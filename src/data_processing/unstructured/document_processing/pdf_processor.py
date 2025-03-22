import boto3
import json
from datetime import datetime
import logging
from typing import Dict, Any, List
import io

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PDFProcessor:
    def __init__(self):
        self.textract = boto3.client('textract')
        self.comprehend = boto3.client('comprehend')
        self.s3 = boto3.client('s3')
        
    def process_pdf(self, bucket: str, key: str) -> Dict[str, Any]:
        """
        Procesa un PDF usando Textract y Comprehend.
        
        Args:
            bucket: Nombre del bucket S3
            key: Ruta del PDF en S3
            
        Returns:
            Dict con resultados del procesamiento
        """
        try:
            # Obtener el PDF de S3
            response = self.s3.get_object(Bucket=bucket, Key=key)
            pdf_bytes = response['Body'].read()
            
            # Procesar con Textract
            textract_response = self.textract.analyze_document(
                Document={'Bytes': pdf_bytes},
                FeatureTypes=['FORMS', 'TABLES']
            )
            
            # Extraer texto
            text = self._extract_text(textract_response)
            
            # Analizar con Comprehend
            entities = self._analyze_entities(text)
            key_phrases = self._analyze_key_phrases(text)
            
            # Procesar resultados
            result = {
                'document_id': key,
                'timestamp': datetime.utcnow().isoformat(),
                'text_analysis': {
                    'raw_text': text,
                    'blocks': textract_response.get('Blocks', []),
                    'forms': self._extract_forms(textract_response),
                    'tables': self._extract_tables(textract_response)
                },
                'nlp_analysis': {
                    'entities': entities,
                    'key_phrases': key_phrases
                },
                'metadata': {
                    'bucket': bucket,
                    'key': key,
                    'size': response.get('ContentLength', 0),
                    'pages': textract_response.get('DocumentMetadata', {}).get('Pages', 0)
                }
            }
            
            logger.info(f"Procesamiento completado para documento: {key}")
            return result
            
        except Exception as e:
            logger.error(f"Error al procesar documento {key}: {str(e)}")
            raise
            
    def _extract_text(self, textract_response: Dict[str, Any]) -> str:
        """
        Extrae texto del documento.
        
        Args:
            textract_response: Respuesta de Textract
            
        Returns:
            Texto extraído
        """
        text = []
        for block in textract_response.get('Blocks', []):
            if block['BlockType'] == 'LINE':
                text.append(block['Text'])
        return ' '.join(text)
        
    def _extract_forms(self, textract_response: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extrae formularios del documento.
        
        Args:
            textract_response: Respuesta de Textract
            
        Returns:
            Lista de formularios
        """
        forms = []
        current_form = {}
        
        for block in textract_response.get('Blocks', []):
            if block['BlockType'] == 'KEY_VALUE_SET':
                if 'KEY' in block['EntityTypes']:
                    current_form['key'] = block['Text']
                elif 'VALUE' in block['EntityTypes']:
                    current_form['value'] = block['Text']
                    forms.append(current_form.copy())
                    current_form = {}
                    
        return forms
        
    def _extract_tables(self, textract_response: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extrae tablas del documento.
        
        Args:
            textract_response: Respuesta de Textract
            
        Returns:
            Lista de tablas
        """
        tables = []
        current_table = []
        
        for block in textract_response.get('Blocks', []):
            if block['BlockType'] == 'TABLE':
                table_id = block['Id']
                cells = []
                
                for cell in textract_response.get('Blocks', []):
                    if cell['BlockType'] == 'CELL' and cell.get('Relationships', [{}])[0].get('Ids', [])[0] == table_id:
                        cells.append(cell['Text'])
                        
                if cells:
                    current_table.append(cells)
                else:
                    if current_table:
                        tables.append(current_table)
                        current_table = []
                        
        if current_table:
            tables.append(current_table)
            
        return tables
        
    def _analyze_entities(self, text: str) -> Dict[str, Any]:
        """
        Analiza entidades en el texto.
        
        Args:
            text: Texto a analizar
            
        Returns:
            Entidades detectadas
        """
        try:
            response = self.comprehend.detect_entities(
                Text=text,
                LanguageCode='es'
            )
            
            return {
                'entities': response['Entities'],
                'timestamp': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error en análisis de entidades: {str(e)}")
            return {'entities': [], 'error': str(e)}
            
    def _analyze_key_phrases(self, text: str) -> Dict[str, Any]:
        """
        Analiza frases clave en el texto.
        
        Args:
            text: Texto a analizar
            
        Returns:
            Frases clave detectadas
        """
        try:
            response = self.comprehend.detect_key_phrases(
                Text=text,
                LanguageCode='es'
            )
            
            return {
                'key_phrases': response['KeyPhrases'],
                'timestamp': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error en análisis de frases clave: {str(e)}")
            return {'key_phrases': [], 'error': str(e)}

def main():
    """
    Función principal para procesar PDFs.
    """
    processor = PDFProcessor()
    
    # Ejemplo de uso
    bucket = 'fraud-detection-documents'
    key = 'reports/sample_report.pdf'
    
    try:
        # Procesar documento
        result = processor.process_pdf(bucket, key)
        
        # Guardar resultados
        output_key = f"analysis_results/{key.split('/')[-1]}_analysis.json"
        processor.s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=json.dumps(result)
        )
        
        logger.info(f"Resultados guardados en: {output_key}")
        
    except Exception as e:
        logger.error(f"Error en el procesamiento: {str(e)}")
        raise

if __name__ == "__main__":
    main() 