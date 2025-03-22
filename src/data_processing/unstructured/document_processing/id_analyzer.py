import boto3
import json
from datetime import datetime
import logging
from typing import Dict, Any

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class IDDocumentAnalyzer:
    def __init__(self):
        self.rekognition = boto3.client('rekognition')
        self.textract = boto3.client('textract')
        self.s3 = boto3.client('s3')
        
    def analyze_document(self, bucket: str, key: str) -> Dict[str, Any]:
        """
        Analiza un documento de identidad usando Rekognition y Textract.
        
        Args:
            bucket: Nombre del bucket S3
            key: Ruta del documento en S3
            
        Returns:
            Dict con resultados del análisis
        """
        try:
            # Obtener el documento de S3
            response = self.s3.get_object(Bucket=bucket, Key=key)
            image_bytes = response['Body'].read()
            
            # Analizar con Textract
            textract_response = self.textract.detect_document_text(
                Document={'Bytes': image_bytes}
            )
            
            # Analizar con Rekognition
            rekognition_response = self.rekognition.detect_faces(
                Image={'Bytes': image_bytes},
                Attributes=['ALL']
            )
            
            # Procesar resultados
            result = {
                'document_id': key,
                'timestamp': datetime.utcnow().isoformat(),
                'text_analysis': {
                    'raw_text': textract_response.get('Blocks', []),
                    'confidence': textract_response.get('DocumentMetadata', {}).get('Pages', 0)
                },
                'face_analysis': {
                    'face_count': len(rekognition_response.get('FaceDetails', [])),
                    'face_details': rekognition_response.get('FaceDetails', [])
                },
                'metadata': {
                    'bucket': bucket,
                    'key': key,
                    'size': response.get('ContentLength', 0)
                }
            }
            
            logger.info(f"Análisis completado para documento: {key}")
            return result
            
        except Exception as e:
            logger.error(f"Error al analizar documento {key}: {str(e)}")
            raise

    def validate_document(self, analysis_result: Dict[str, Any]) -> Dict[str, Any]:
        """
        Valida los resultados del análisis del documento.
        
        Args:
            analysis_result: Resultados del análisis
            
        Returns:
            Dict con resultados de la validación
        """
        validation = {
            'is_valid': True,
            'issues': [],
            'confidence_score': 0.0
        }
        
        # Validar presencia de texto
        if not analysis_result['text_analysis']['raw_text']:
            validation['is_valid'] = False
            validation['issues'].append('No se detectó texto en el documento')
            
        # Validar presencia de rostro
        if analysis_result['face_analysis']['face_count'] == 0:
            validation['is_valid'] = False
            validation['issues'].append('No se detectó rostro en el documento')
            
        # Calcular score de confianza
        text_confidence = analysis_result['text_analysis']['confidence']
        face_confidence = sum(
            face.get('Confidence', 0) 
            for face in analysis_result['face_analysis']['face_details']
        ) / max(1, analysis_result['face_analysis']['face_count'])
        
        validation['confidence_score'] = (text_confidence + face_confidence) / 2
        
        return validation

def main():
    """
    Función principal para procesar documentos de identidad.
    """
    analyzer = IDDocumentAnalyzer()
    
    # Ejemplo de uso
    bucket = 'fraud-detection-documents'
    key = 'identity_documents/sample_id.jpg'
    
    try:
        # Analizar documento
        analysis_result = analyzer.analyze_document(bucket, key)
        
        # Validar resultados
        validation_result = analyzer.validate_document(analysis_result)
        
        # Guardar resultados
        output_key = f"analysis_results/{key.split('/')[-1]}_analysis.json"
        analyzer.s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=json.dumps({
                'analysis': analysis_result,
                'validation': validation_result
            })
        )
        
        logger.info(f"Resultados guardados en: {output_key}")
        
    except Exception as e:
        logger.error(f"Error en el procesamiento: {str(e)}")
        raise

if __name__ == "__main__":
    main() 