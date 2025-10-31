import tensorflow as tf
from tensorflow.keras import layers, models, regularizers
from tensorflow.keras.applications import MobileNetV2, EfficientNetB0
import numpy as np

class SignLanguageModel:
    def __init__(self, input_shape=(224, 224, 3), num_classes=26, model_type='cnn'):
        self.input_shape = input_shape
        self.num_classes = num_classes
        self.model_type = model_type
        self.model = None
    
    def build_cnn_model(self):
        """Modelo CNN personalizado para lenguaje de señas"""
        model = models.Sequential([
            # Capa de entrada
            layers.Input(shape=self.input_shape),
            
            # Primer bloque convolucional
            layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Segundo bloque convolucional
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Tercer bloque convolucional
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Cuarto bloque convolucional
            layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Capas fully connected
            layers.Flatten(),
            layers.Dense(512, activation='relu', 
                        kernel_regularizer=regularizers.l2(0.001)),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(256, activation='relu',
                        kernel_regularizer=regularizers.l2(0.001)),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model
    
    def build_transfer_learning_model(self):
        """Modelo con Transfer Learning usando MobileNetV2"""
        base_model = MobileNetV2(
            weights='imagenet',
            include_top=False,
            input_shape=self.input_shape
        )
        
        # Congelar las capas base
        base_model.trainable = False
        
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model
    
    def build_efficientnet_model(self):
        """Modelo con EfficientNet (más preciso pero más lento)"""
        base_model = EfficientNetB0(
            weights='imagenet',
            include_top=False,
            input_shape=self.input_shape
        )
        
        base_model.trainable = False
        
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model
    
    def build_model(self):
        """Construir el modelo según el tipo especificado"""
        if self.model_type == 'transfer_learning':
            return self.build_transfer_learning_model()
        elif self.model_type == 'efficientnet':
            return self.build_efficientnet_model()
        else:  # CNN por defecto
            return self.build_cnn_model()
    
    def compile_model(self, learning_rate=0.001):
        """Compilar el modelo"""
        if self.model is None:
            self.model = self.build_model()
        
        self.model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
            loss='categorical_crossentropy',
            metrics=['accuracy', 'precision', 'recall']
        )
        
        return self.model
    
    def summary(self):
        """Mostrar resumen del modelo"""
        if self.model:
            return self.model.summary()
        else:
            print("Model not built yet. Call build_model() first.")

# Modelo especializado para detección en tiempo real
class RealTimeSignModel:
    def __init__(self, input_shape=(128, 128, 3), num_classes=26):
        self.input_shape = input_shape
        self.num_classes = num_classes
        self.model = None
    
    def build_lightweight_model(self):
        """Modelo liviano para inferencia en tiempo real"""
        model = models.Sequential([
            layers.Input(shape=self.input_shape),
            
            # Bloque 1
            layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.2),
            
            # Bloque 2
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.2),
            
            # Bloque 3
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.2),
            
            # Clasificación
            layers.GlobalAveragePooling2D(),
            layers.Dense(128, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model
    
    def compile(self, learning_rate=0.001):
        self.model = self.build_lightweight_model()
        self.model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        return self.model
    