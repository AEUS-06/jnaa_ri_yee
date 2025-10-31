from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import numpy as np
import cv2
from tensorflow.keras.models import load_model
import json
import os
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Sign Language Translator API", version="1.0.0")

# Configurar CORS para permitir conexiones desde Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica tu IP de Flutter
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variables globales para el modelo
model = None
class_names = []
input_shape = (224, 224, 3)  # Ajusta según tu modelo

def load_ai_model():
    """Cargar el modelo de IA y las clases"""
    global model, class_names
    
    try:
        model_path = "model/model.h5"
        class_names_path = "model/class_names.json"
        
        if not os.path.exists(model_path):
            logger.error(f"Model file not found: {model_path}")
            return False
            
        if not os.path.exists(class_names_path):
            logger.error(f"Class names file not found: {class_names_path}")
            return False
        
        # Cargar modelo
        model = load_model(model_path)
        logger.info("Model loaded successfully")
        
        # Cargar nombres de clases
        with open(class_names_path, 'r') as f:
            class_names = json.load(f)
        logger.info(f"Class names loaded: {class_names}")
        
        return True
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        return False

def preprocess_image(image_data: np.ndarray) -> np.ndarray:
    """Preprocesar la imagen para el modelo"""
    try:
        # Redimensionar a las dimensiones esperadas por el modelo
        image = cv2.resize(image_data, (input_shape[1], input_shape[0]))
        
        # Convertir BGR a RGB si es necesario
        if len(image.shape) == 3 and image.shape[2] == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Normalizar valores de píxeles
        image = image.astype(np.float32) / 255.0
        
        # Agregar dimensión del batch
        image = np.expand_dims(image, axis=0)
        
        return image
        
    except Exception as e:
        logger.error(f"Error preprocessing image: {str(e)}")
        raise

@app.on_event("startup")
async def startup_event():
    """Cargar el modelo al iniciar la aplicación"""
    logger.info("Starting up...")
    if not load_ai_model():
        logger.error("Failed to load AI model on startup")

@app.get("/")
async def root():
    """Endpoint de verificación"""
    return {
        "message": "Sign Language Translator API", 
        "status": "running",
        "model_loaded": model is not None
    }

@app.get("/health")
async def health_check():
    """Endpoint de salud"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "model_loaded": model is not None
    }

@app.post("/predict/")
async def predict_sign_language(file: UploadFile = File(...)):
    """Recibir imagen y predecir la seña"""
    try:
        # Verificar que el modelo esté cargado
        if model is None:
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        # Verificar que sea una imagen
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Leer la imagen
        image_data = await file.read()
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Could not decode image")
        
        logger.info(f"Image received: {image.shape}")
        
        # Preprocesar imagen
        processed_image = preprocess_image(image)
        
        # Realizar predicción
        predictions = model.predict(processed_image)
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        
        # Obtener nombre de la clase
        if predicted_class_idx < len(class_names):
            predicted_class = class_names[predicted_class_idx]
        else:
            predicted_class = f"Class_{predicted_class_idx}"
        
        logger.info(f"Prediction: {predicted_class} (confidence: {confidence:.2f})")
        
        return JSONResponse({
            "prediction": predicted_class,
            "confidence": confidence,
            "all_predictions": {
                class_names[i] if i < len(class_names) else f"Class_{i}": float(predictions[0][i])
                for i in range(len(predictions[0]))
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",  # Escuchar en todas las interfaces
        port=8000,
        reload=True,  # Solo para desarrollo
        log_level="info"
    )