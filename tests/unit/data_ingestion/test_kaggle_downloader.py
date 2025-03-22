import os
import unittest
from unittest.mock import patch, MagicMock
from modules.data_ingestion.src.functions.kaggle_downloader.main import setup_kaggle, process_dataset

class TestKaggleDownloader(unittest.TestCase):
    @patch.dict(os.environ, {'KAGGLE_USERNAME': 'test_user', 'KAGGLE_KEY': 'test_key'})
    def test_setup_kaggle(self):
        """Prueba la configuración de credenciales de Kaggle."""
        setup_kaggle()
        kaggle_dir = os.path.expanduser('~/.kaggle')
        self.assertTrue(os.path.exists(kaggle_dir))
        self.assertTrue(os.path.exists(os.path.join(kaggle_dir, 'kaggle.json')))

    @patch('kaggle.api')
    @patch('boto3.client')
    def test_process_dataset(self, mock_s3, mock_kaggle):
        """Prueba el proceso de descarga y carga del dataset."""
        # Configurar mocks
        mock_kaggle.dataset_download_files.return_value = None
        mock_s3.upload_fileobj.return_value = None
        
        # Crear archivo temporal para simular descarga
        with open('/tmp/test.csv', 'w') as f:
            f.write('test data')
        
        # Ejecutar función
        result = process_dataset()
        
        # Verificar llamadas
        mock_kaggle.dataset_download_files.assert_called_once()
        mock_s3.upload_fileobj.assert_called_once()
        
        # Limpiar
        os.remove('/tmp/test.csv')
        
        self.assertIsNotNone(result)

if __name__ == '__main__':
    unittest.main() 