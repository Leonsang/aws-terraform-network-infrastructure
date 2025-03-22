import os
import kaggle
from kaggle.api.kaggle_api_extended import KaggleApi

def download_fraud_dataset():
    # Inicializar la API de Kaggle
    api = KaggleApi()
    api.authenticate()
    
    # Crear directorio para los datos si no existe
    os.makedirs('data/raw', exist_ok=True)
    
    # Descargar el dataset de fraude
    api.dataset_download_files(
        'mlg-ulb/creditcardfraud',
        path='data/raw',
        unzip=True
    )
    
    print("Dataset descargado exitosamente")

if __name__ == "__main__":
    download_fraud_dataset() 