"""
Script para generar un modelo de ejemplo si no tienes datos de entrenamiento
"""
import tensorflow as tf
import numpy as np
import json
import os

def create_sample_model():
    """Crear un modelo de ejemplo pre-entrenado para pruebas"""
    
    # Clases de ejemplo (alfabeto de señas básico)
    class_names = ['A', 'E', 'I', 'O', 'U']
    
    # Crear un modelo simple
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(128, 128, 3)),
        tf.keras.layers.Conv2D(32, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Conv2D(64, 3, activation='relu'),
        tf.keras.layers.MaxPooling2D(),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dense(len(class_names), activation='softmax')
    ])
    
    # Compilar el modelo
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Crear datos dummy para "entrenar" el modelo rápidamente
    print("Creating sample model with dummy data...")
    
    # Generar datos de ejemplo
    X_dummy = np.random.random((100, 128, 128, 3)).astype(np.float32)
    y_dummy = tf.keras.utils.to_categorical(
        np.random.randint(0, len(class_names), 100), 
        len(class_names)
    )
    
    # "Entrenamiento" rápido
    model.fit(X_dummy, y_dummy, epochs=1, verbose=1)
    
    # Crear directorio si no existe
    os.makedirs('model', exist_ok=True)
    
    # Guardar modelo
    model.save('model/model.h5')
    print("Sample model saved as model/model.h5")
    
    # Guardar nombres de clases
    with open('model/class_names.json', 'w') as f:
        json.dump(class_names, f, indent=2)
    print("Class names saved as model/class_names.json")
    
    print("\n¡Modelo de ejemplo generado exitosamente!")
    print("Puedes ejecutar el servidor FastAPI con: python main.py")
    print("NOTA: Este es un modelo de ejemplo. Para mejor precisión, entrena con datos reales.")

if __name__ == "__main__":
    create_sample_model()