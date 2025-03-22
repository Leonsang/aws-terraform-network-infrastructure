import os
import json
import boto3
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from lightgbm import LGBMClassifier
import joblib

# Configuración de paths en SageMaker
prefix = "/opt/ml"
input_path = os.path.join(prefix, "input/data")
output_path = os.path.join(prefix, "model")
model_path = os.path.join(output_path, "model.joblib")
param_path = os.path.join(prefix, "input/config/hyperparameters.json")

def load_training_data(input_path):
    """Carga los datos de entrenamiento desde S3."""
    training_path = os.path.join(input_path, "training")
    data = pd.read_parquet(os.path.join(training_path, "features.parquet"))
    
    # Separar features y target
    X = data.drop(['is_fraud', 'transaction_id', 'customer_id', 'timestamp'], axis=1)
    y = data['is_fraud']
    
    return train_test_split(X, y, test_size=0.2, random_state=42)

def train(X_train, X_val, y_train, y_val, params):
    """Entrena el modelo LightGBM."""
    model = LGBMClassifier(
        n_estimators=params.get('n_estimators', 100),
        learning_rate=params.get('learning_rate', 0.1),
        max_depth=params.get('max_depth', 7),
        num_leaves=params.get('num_leaves', 31),
        class_weight='balanced',
        random_state=42
    )
    
    # Entrenamiento con early stopping
    model.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        eval_metric='auc',
        early_stopping_rounds=10,
        verbose=10
    )
    
    return model

def save_model(model, model_path):
    """Guarda el modelo entrenado."""
    joblib.dump(model, model_path)

def main():
    print("Iniciando entrenamiento...")
    
    # Cargar hiperparámetros
    with open(param_path, 'r') as f:
        hyperparameters = json.load(f)
    
    # Convertir strings a tipos correctos
    params = {
        'n_estimators': int(hyperparameters.get('n_estimators', 100)),
        'learning_rate': float(hyperparameters.get('learning_rate', 0.1)),
        'max_depth': int(hyperparameters.get('max_depth', 7)),
        'num_leaves': int(hyperparameters.get('num_leaves', 31))
    }
    
    print("Cargando datos...")
    X_train, X_val, y_train, y_val = load_training_data(input_path)
    
    print("Escalando features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    
    print("Entrenando modelo...")
    model = train(X_train_scaled, X_val_scaled, y_train, y_val, params)
    
    print("Guardando modelo...")
    os.makedirs(output_path, exist_ok=True)
    save_model({'model': model, 'scaler': scaler}, model_path)
    
    print("Entrenamiento completado.")

if __name__ == '__main__':
    main() 