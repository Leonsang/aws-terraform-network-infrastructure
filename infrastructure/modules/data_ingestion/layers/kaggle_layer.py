import kaggle
import pandas as pd
import numpy as np

def download_dataset(dataset_name, path):
    """
    Descarga un dataset de Kaggle
    
    Args:
        dataset_name (str): Nombre del dataset en formato 'username/dataset-name'
        path (str): Ruta donde se guardará el dataset
        
    Returns:
        str: Ruta del archivo descargado
    """
    try:
        kaggle.api.dataset_download_files(dataset_name, path=path, unzip=True)
        return path
    except Exception as e:
        print(f"Error al descargar el dataset: {str(e)}")
        raise

def process_data(file_path):
    """
    Procesa los datos descargados
    
    Args:
        file_path (str): Ruta del archivo a procesar
        
    Returns:
        pd.DataFrame: DataFrame procesado
    """
    try:
        df = pd.read_csv(file_path)
        # Aquí puedes agregar el procesamiento específico que necesites
        return df
    except Exception as e:
        print(f"Error al procesar los datos: {str(e)}")
        raise 