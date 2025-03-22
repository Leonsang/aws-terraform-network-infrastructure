import os
import json
import joblib
import numpy as np
from io import StringIO
import pandas as pd

def model_fn(model_dir):
    """Carga el modelo guardado."""
    model_path = os.path.join(model_dir, "model.joblib")
    model_dict = joblib.load(model_path)
    return model_dict

def input_fn(request_body, request_content_type):
    """Procesa la entrada para predicción."""
    if request_content_type == "application/json":
        # Parsear JSON
        input_data = json.loads(request_body)
        # Convertir a DataFrame
        return pd.DataFrame([input_data])
    else:
        raise ValueError(f"Content type {request_content_type} no soportado")

def predict_fn(input_data, model_dict):
    """Realiza la predicción."""
    # Extraer modelo y scaler
    model = model_dict['model']
    scaler = model_dict['scaler']
    
    # Preparar features
    features = input_data.drop(['transaction_id', 'customer_id', 'timestamp'], axis=1, errors='ignore')
    
    # Escalar features
    features_scaled = scaler.transform(features)
    
    # Realizar predicción
    prediction_proba = model.predict_proba(features_scaled)
    
    return prediction_proba[:, 1]  # Retorna probabilidad de fraude

def output_fn(prediction, accept):
    """Formatea la salida de la predicción."""
    if accept == "application/json":
        response = {
            "fraud_probability": float(prediction[0]),
            "is_fraud": bool(prediction[0] > 0.5)
        }
        return json.dumps(response)
    raise ValueError(f"Accept type {accept} no soportado") 