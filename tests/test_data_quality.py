import unittest
import pandas as pd
import numpy as np
from scripts.lambda.data_quality_lambda import validate_identity_file

class TestDataQuality(unittest.TestCase):
    def setUp(self):
        """Configuración inicial para las pruebas"""
        self.test_bucket = "test-bucket"
        self.test_key = "test-file.csv"
        
    def test_valid_data(self):
        """Prueba con datos válidos"""
        # Crear DataFrame de prueba con datos válidos
        df = pd.DataFrame({
            "TransactionID": [1, 2, 3],
            "DeviceType": ["mobile", "desktop", "mobile"]
        })
        
        # Simular carga de archivo
        with unittest.mock.patch('scripts.lambda.data_quality_lambda.load_file_to_dataframe') as mock_load:
            mock_load.return_value = df
            result = validate_identity_file(self.test_bucket, self.test_key)
            
            self.assertEqual(result["status"], "success")
            self.assertEqual(result["stats"]["total_rows"], 3)
            self.assertEqual(result["stats"]["unique_transaction_ids"], 3)
            
    def test_missing_columns(self):
        """Prueba con columnas faltantes"""
        # Crear DataFrame sin columnas requeridas
        df = pd.DataFrame({
            "DeviceType": ["mobile", "desktop"]
        })
        
        with unittest.mock.patch('scripts.lambda.data_quality_lambda.load_file_to_dataframe') as mock_load:
            mock_load.return_value = df
            result = validate_identity_file(self.test_bucket, self.test_key)
            
            self.assertEqual(result["status"], "error")
            self.assertIn("Columnas requeridas faltantes", result["message"])
            
    def test_duplicate_transactions(self):
        """Prueba con transacciones duplicadas"""
        # Crear DataFrame con duplicados
        df = pd.DataFrame({
            "TransactionID": [1, 1, 3],
            "DeviceType": ["mobile", "desktop", "mobile"]
        })
        
        with unittest.mock.patch('scripts.lambda.data_quality_lambda.load_file_to_dataframe') as mock_load:
            mock_load.return_value = df
            result = validate_identity_file(self.test_bucket, self.test_key)
            
            self.assertEqual(result["status"], "warning")
            self.assertIn("TransactionID duplicados", result["message"])
            
    def test_load_error(self):
        """Prueba con error al cargar el archivo"""
        with unittest.mock.patch('scripts.lambda.data_quality_lambda.load_file_to_dataframe') as mock_load:
            mock_load.return_value = None
            result = validate_identity_file(self.test_bucket, self.test_key)
            
            self.assertEqual(result["status"], "error")
            self.assertIn("No se pudo cargar el archivo", result["message"])

if __name__ == '__main__':
    unittest.main() 