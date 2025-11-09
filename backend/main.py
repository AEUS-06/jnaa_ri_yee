# main.py
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn, os, json, asyncio, numpy as np, cv2, joblib, logging
from datetime import datetime
from model import DLClassifier, FeatureExtractor, load_class_names

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("sign-translator")

app = FastAPI(title="Sign Language Translator API (ensemble)", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "model", "models")
KERAS_MODEL = os.path.join(MODEL_DIR, "vowels_model.h5")
ML_MODEL = os.path.join(MODEL_DIR, "ml_rf_joblib.pkl")
CLASS_NAMES = os.path.join(MODEL_DIR, "class_names.json")

dl = None
fe = None
ml = None
class_names = []

INPUT_SHAPE = (224,224,3)

def load_models():
    global dl, fe, ml, class_names
    if not os.path.exists(KERAS_MODEL) or not os.path.exists(ML_MODEL) or not os.path.exists(CLASS_NAMES):
        logger.error("Model files missing. Check model/models/ for artifacts.")
        return False
    dl = DLClassifier(model_path=KERAS_MODEL, input_shape=INPUT_SHAPE)
    fe = FeatureExtractor(input_shape=INPUT_SHAPE)
    ml = joblib.load(ML_MODEL)
    with open(CLASS_NAMES, 'r', encoding='utf-8') as f:
        class_names = json.load(f)
    logger.info("Models loaded. Classes: %s", class_names)
    return True

@app.on_event("startup")
async def startup():
    ok = load_models()
    if not ok:
        logger.error("Models not loaded on startup.")

def preprocess_cv_image(cv_img, target=(224,224)):
    img = cv2.resize(cv_img, target)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    arr = img.astype('float32') / 255.0
    return np.expand_dims(arr, axis=0)

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    try:
        if dl is None or fe is None or ml is None:
            raise HTTPException(status_code=503, detail="Model not ready")
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Invalid file type")

        data = await file.read()
        nparr = np.frombuffer(data, np.uint8)
        cv_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if cv_img is None:
            raise HTTPException(status_code=400, detail="Could not decode image")

        x = preprocess_cv_image(cv_img, target=(224,224))  # (1,224,224,3)

        # DL probs
        loop = asyncio.get_event_loop()
        dl_probs = await loop.run_in_executor(None, dl.predict_proba, x)  # (1,C)

        # ML probs: extract features
        feat = fe.extract(x)  # (1,feat_dim)
        ml_probs = ml.predict_proba(feat)

        # ensemble average
        # make sure shapes align (safety)
        min_len = min(dl_probs.shape[1], ml_probs.shape[1])
        dl_p = dl_probs[:, :min_len]
        ml_p = ml_probs[:, :min_len]
        ensemble = (dl_p + ml_p) / 2.0
        idx = int(np.argmax(ensemble[0]))
        conf = float(np.max(ensemble[0]))
        label = class_names[idx] if idx < len(class_names) else f"Class_{idx}"

        logger.info("Prediction: %s (%.3f)", label, conf)
        return JSONResponse({"prediction": label, "confidence": round(conf,4), "timestamp": datetime.now().isoformat()})

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Error in predict")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
