import boto3
import json
from datetime import datetime
import logging
from typing import Dict, Any
import time

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CallAnalyzer:
    def __init__(self):
        self.transcribe = boto3.client('transcribe')
        self.comprehend = boto3.client('comprehend')
        self.s3 = boto3.client('s3')
        
    def start_transcription(self, bucket: str, key: str) -> str:
        """
        Inicia un trabajo de transcripción para un archivo de audio.
        
        Args:
            bucket: Nombre del bucket S3
            key: Ruta del archivo de audio en S3
            
        Returns:
            ID del trabajo de transcripción
        """
        job_name = f"transcription_{int(time.time())}"
        
        try:
            response = self.transcribe.start_transcription_job(
                TranscriptionJobName=job_name,
                Media={'MediaFileUri': f's3://{bucket}/{key}'},
                MediaFormat='mp3',
                LanguageCode='es-ES',
                Settings={
                    'ShowSpeakerLabels': True,
                    'MaxSpeakerLabels': 2
                },
                OutputBucketName=bucket,
                OutputKey=f'transcriptions/{job_name}.json'
            )
            
            logger.info(f"Trabajo de transcripción iniciado: {job_name}")
            return job_name
            
        except Exception as e:
            logger.error(f"Error al iniciar transcripción: {str(e)}")
            raise
            
    def wait_for_transcription(self, job_name: str, max_attempts: int = 60) -> Dict[str, Any]:
        """
        Espera a que se complete la transcripción.
        
        Args:
            job_name: ID del trabajo de transcripción
            max_attempts: Número máximo de intentos
            
        Returns:
            Resultados de la transcripción
        """
        for attempt in range(max_attempts):
            response = self.transcribe.get_transcription_job(
                TranscriptionJobName=job_name
            )
            
            status = response['TranscriptionJob']['TranscriptionJobStatus']
            
            if status == 'COMPLETED':
                output_key = response['TranscriptionJob']['Transcript']['TranscriptFileUri']
                bucket = output_key.split('/')[2]
                key = '/'.join(output_key.split('/')[3:])
                
                result = self.s3.get_object(Bucket=bucket, Key=key)
                return json.loads(result['Body'].read().decode('utf-8'))
                
            elif status == 'FAILED':
                raise Exception(f"Transcripción fallida: {response['TranscriptionJob']['FailureReason']}")
                
            time.sleep(30)  # Esperar 30 segundos antes de reintentar
            
        raise Exception("Tiempo de espera agotado para la transcripción")
        
    def analyze_sentiment(self, text: str) -> Dict[str, Any]:
        """
        Analiza el sentimiento del texto transcrito.
        
        Args:
            text: Texto a analizar
            
        Returns:
            Resultados del análisis de sentimiento
        """
        try:
            response = self.comprehend.detect_sentiment(
                Text=text,
                LanguageCode='es'
            )
            
            return {
                'sentiment': response['Sentiment'],
                'scores': response['SentimentScore'],
                'timestamp': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error en análisis de sentimiento: {str(e)}")
            raise
            
    def detect_entities(self, text: str) -> Dict[str, Any]:
        """
        Detecta entidades en el texto transcrito.
        
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
            logger.error(f"Error en detección de entidades: {str(e)}")
            raise

def main():
    """
    Función principal para procesar llamadas.
    """
    analyzer = CallAnalyzer()
    
    # Ejemplo de uso
    bucket = 'fraud-detection-calls'
    key = 'calls/sample_call.mp3'
    
    try:
        # Iniciar transcripción
        job_name = analyzer.start_transcription(bucket, key)
        
        # Esperar y obtener resultados
        transcription_result = analyzer.wait_for_transcription(job_name)
        
        # Extraer texto transcrito
        transcript = transcription_result['results']['transcripts'][0]['transcript']
        
        # Analizar sentimiento
        sentiment_result = analyzer.analyze_sentiment(transcript)
        
        # Detectar entidades
        entities_result = analyzer.detect_entities(transcript)
        
        # Guardar resultados
        output_key = f"analysis_results/{key.split('/')[-1]}_analysis.json"
        analyzer.s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=json.dumps({
                'transcription': transcription_result,
                'sentiment': sentiment_result,
                'entities': entities_result,
                'metadata': {
                    'bucket': bucket,
                    'key': key,
                    'job_name': job_name,
                    'timestamp': datetime.utcnow().isoformat()
                }
            })
        )
        
        logger.info(f"Resultados guardados en: {output_key}")
        
    except Exception as e:
        logger.error(f"Error en el procesamiento: {str(e)}")
        raise

if __name__ == "__main__":
    main() 