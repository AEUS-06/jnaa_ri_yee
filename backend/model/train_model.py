import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import (
    EarlyStopping, 
    ReduceLROnPlateau, 
    ModelCheckpoint, 
    TensorBoard
)
import numpy as np
import json
import os
import cv2
from pathlib import Path
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns

from model import SignLanguageModel, RealTimeSignModel

class SignLanguageTrainer:
    def __init__(self, data_dir, model_type='cnn', input_shape=(224, 224, 3)):
        self.data_dir = Path(data_dir)
        self.model_type = model_type
        self.input_shape = input_shape
        self.model = None
        self.class_names = []
        self.history = None
        
    def load_and_prepare_data(self, test_size=0.2, validation_size=0.2):
        """Cargar y preparar los datos para entrenamiento"""
        print("Loading dataset...")
        
        images = []
        labels = []
        
        # Obtener nombres de clases desde las subcarpetas
        self.class_names = sorted([d.name for d in self.data_dir.iterdir() if d.is_dir()])
        self.num_classes = len(self.class_names)
        
        print(f"Found {self.num_classes} classes: {self.class_names}")
        
        for class_idx, class_name in enumerate(self.class_names):
            class_dir = self.data_dir / class_name
            image_files = list(class_dir.glob('*.jpg')) + list(class_dir.glob('*.png')) + list(class_dir.glob('*.jpeg'))
            
            print(f"Loading {len(image_files)} images from {class_name}")
            
            for img_path in image_files:
                try:
                    # Cargar imagen
                    image = cv2.imread(str(img_path))
                    if image is not None:
                        # Convertir BGR a RGB
                        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                        # Redimensionar
                        image = cv2.resize(image, (self.input_shape[1], self.input_shape[0]))
                        images.append(image)
                        labels.append(class_idx)
                except Exception as e:
                    print(f"Error loading image {img_path}: {e}")
        
        if len(images) == 0:
            raise ValueError("No images found in the dataset directory")
        
        # Convertir a arrays numpy
        X = np.array(images, dtype='float32')
        y = np.array(labels)
        
        # Normalizar
        X = X / 255.0
        
        print(f"Dataset loaded: {X.shape[0]} images, {self.num_classes} classes")
        
        # Dividir en train, validation y test
        X_temp, X_test, y_temp, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        X_train, X_val, y_train, y_val = train_test_split(
            X_temp, y_temp, test_size=validation_size, random_state=42, stratify=y_temp
        )
        
        # Convertir labels a categorical
        y_train_cat = tf.keras.utils.to_categorical(y_train, self.num_classes)
        y_val_cat = tf.keras.utils.to_categorical(y_val, self.num_classes)
        y_test_cat = tf.keras.utils.to_categorical(y_test, self.num_classes)
        
        return (X_train, y_train_cat), (X_val, y_val_cat), (X_test, y_test_cat), y_test
    
    def create_data_generator(self):
        """Crear generador de datos con aumentación"""
        train_datagen = ImageDataGenerator(
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.2,
            zoom_range=0.2,
            horizontal_flip=True,
            fill_mode='nearest',
            brightness_range=[0.8, 1.2]
        )
        
        return train_datagen
    
    def build_model(self):
        """Construir el modelo según el tipo especificado"""
        if self.model_type == 'realtime':
            model_builder = RealTimeSignModel(
                input_shape=self.input_shape,
                num_classes=self.num_classes
            )
        else:
            model_builder = SignLanguageModel(
                input_shape=self.input_shape,
                num_classes=self.num_classes,
                model_type=self.model_type
            )
        
        self.model = model_builder.compile_model(learning_rate=0.001)
        return self.model
    
    def train(self, epochs=100, batch_size=32):
        """Entrenar el modelo"""
        # Cargar datos
        (X_train, y_train), (X_val, y_val), (X_test, y_test), y_test_labels = self.load_and_prepare_data()
        
        # Construir modelo
        self.build_model()
        
        print("Model architecture:")
        self.model.summary()
        
        # Callbacks
        callbacks = [
            EarlyStopping(
                monitor='val_accuracy',
                patience=15,
                restore_best_weights=True,
                verbose=1
            ),
            ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=8,
                min_lr=1e-7,
                verbose=1
            ),
            ModelCheckpoint(
                'model/best_model.h5',
                monitor='val_accuracy',
                save_best_only=True,
                mode='max',
                verbose=1
            ),
            TensorBoard(
                log_dir='./logs',
                histogram_freq=1
            )
        ]
        
        # Data augmentation
        datagen = self.create_data_generator()
        
        print("Starting training...")
        print(f"Training samples: {X_train.shape[0]}")
        print(f"Validation samples: {X_val.shape[0]}")
        print(f"Test samples: {X_test.shape[0]}")
        
        # Entrenar con data augmentation
        self.history = self.model.fit(
            datagen.flow(X_train, y_train, batch_size=batch_size),
            steps_per_epoch=len(X_train) // batch_size,
            epochs=epochs,
            validation_data=(X_val, y_val),
            callbacks=callbacks,
            verbose=1
        )
        
        # Evaluar con test set
        print("\nEvaluating on test set...")
        test_loss, test_accuracy = self.model.evaluate(X_test, y_test, verbose=1)
        print(f"Test Accuracy: {test_accuracy:.4f}")
        print(f"Test Loss: {test_loss:.4f}")
        
        # Generar reporte de clasificación
        y_pred = self.model.predict(X_test)
        y_pred_classes = np.argmax(y_pred, axis=1)
        
        print("\nClassification Report:")
        print(classification_report(y_test_labels, y_pred_classes, 
                                  target_names=self.class_names))
        
        return self.history
    
    def save_model(self, model_path='model/model.h5', class_names_path='model/class_names.json'):
        """Guardar modelo y metadatos"""
        # Crear directorios si no existen
        os.makedirs('model', exist_ok=True)
        
        # Guardar modelo
        self.model.save(model_path)
        print(f"Model saved to {model_path}")
        
        # Guardar nombres de clases
        with open(class_names_path, 'w') as f:
            json.dump(self.class_names, f, indent=2)
        print(f"Class names saved to {class_names_path}")
        
        # Guardar arquitectura del modelo
        with open('model/model_architecture.json', 'w') as f:
            f.write(self.model.to_json())
    
    def plot_training_history(self):
        """Graficar el historial de entrenamiento"""
        if self.history is None:
            print("No training history available. Train the model first.")
            return
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
        
        # Gráfica de accuracy
        ax1.plot(self.history.history['accuracy'], label='Training Accuracy')
        ax1.plot(self.history.history['val_accuracy'], label='Validation Accuracy')
        ax1.set_title('Model Accuracy')
        ax1.set_xlabel('Epoch')
        ax1.set_ylabel('Accuracy')
        ax1.legend()
        
        # Gráfica de loss
        ax2.plot(self.history.history['loss'], label='Training Loss')
        ax2.plot(self.history.history['val_loss'], label='Validation Loss')
        ax2.set_title('Model Loss')
        ax2.set_xlabel('Epoch')
        ax2.set_ylabel('Loss')
        ax2.legend()
        
        plt.tight_layout()
        plt.savefig('model/training_history.png', dpi=300, bbox_inches='tight')
        plt.show()

def create_sample_data_for_testing():
    """Crear datos de ejemplo para probar el modelo"""
    print("Creating sample data for testing...")
    
    # Crear directorios de ejemplo para el alfabeto de señas
    classes = ['A', 'E', 'I', 'O', 'U']
    
    for class_name in classes:
        os.makedirs(f'dataset/train/{class_name}', exist_ok=True)
    
    print("Sample directory structure created.")
    print("Please add your actual sign language images to these folders.")

if __name__ == "__main__":
    # Configuración
    DATA_DIR = "dataset/train"  # Cambia esta ruta
    MODEL_TYPE = "cnn"  # "cnn", "transfer_learning", "realtime"
    INPUT_SHAPE = (128, 128, 3)  # Para tiempo real usar (128, 128, 3)
    EPOCHS = 100
    BATCH_SIZE = 32
    
    # Verificar si el dataset existe
    if not os.path.exists(DATA_DIR):
        print(f"Dataset directory {DATA_DIR} not found.")
        create_sample_data_for_testing()
        print("Please add your training images and run again.")
        exit()
    
    # Crear y entrenar modelo
    trainer = SignLanguageTrainer(
        data_dir=DATA_DIR,
        model_type=MODEL_TYPE,
        input_shape=INPUT_SHAPE
    )
    
    try:
        # Entrenar modelo
        history = trainer.train(
            epochs=EPOCHS,
            batch_size=BATCH_SIZE
        )
        
        # Guardar modelo
        trainer.save_model()
        
        # Graficar resultados
        trainer.plot_training_history()
        
        print("\n" + "="*50)
        print("TRAINING COMPLETED SUCCESSFULLY!")
        print("="*50)
        print(f"Model saved as: model/model.h5")
        print(f"Class names saved as: model/class_names.json")
        print(f"Model ready for use with FastAPI backend!")
        
    except Exception as e:
        print(f"Error during training: {str(e)}")
        import traceback
        traceback.print_exc()