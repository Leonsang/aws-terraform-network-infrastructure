# Diagrama de Arquitectura del Sistema

Este directorio contiene los archivos necesarios para generar el diagrama de arquitectura del sistema de detección de fraude financiero.

## Archivos disponibles

1. `architecture.puml` - Archivo fuente en formato PlantUML
2. `architecture.png.txt` - Representación ASCII del diagrama (para referencia)

## Cómo generar la imagen

Para generar la imagen a partir del archivo PlantUML, puedes utilizar alguna de las siguientes opciones:

### Opción 1: Usar el servicio web de PlantUML

1. Visita [PlantUML Web Server](http://www.plantuml.com/plantuml/uml/)
2. Copia y pega el contenido del archivo `architecture.puml`
3. La imagen se generará automáticamente
4. Descarga la imagen como PNG

### Opción 2: Usar la extensión de PlantUML para VS Code

1. Instala la extensión "PlantUML" en VS Code
2. Abre el archivo `architecture.puml`
3. Presiona Alt+D para previsualizar el diagrama
4. Exporta la imagen como PNG

### Opción 3: Usar la línea de comandos

```bash
java -jar plantuml.jar architecture.puml
```

## Descripción de la Arquitectura

El diagrama muestra la arquitectura Lakehouse implementada para el sistema de detección de fraude financiero, con tres zonas principales:

1. **Raw Zone (Bronze)** - Almacenamiento de datos sin procesar
   - S3 Bucket para datos raw
   - Glue Crawler para catalogación

2. **Processed Zone (Silver)** - Datos limpios y transformados
   - Glue ETL Job para transformación
   - Lambda Function para validación de calidad
   - S3 Bucket para datos procesados

3. **Analytics Zone (Gold)** - Vistas materializadas para análisis
   - S3 Bucket para vistas materializadas
   - Redshift Cluster para data warehouse
   - QuickSight para dashboards

Además, incluye componentes para:

- **Ingesta de Datos**
  - Lambda Function para descarga automática desde Kaggle
  - Kinesis Stream para ingesta en tiempo real

- **Procesamiento en Tiempo Real**
  - Lambda Function para detección de fraude en tiempo real
  - DynamoDB para estadísticas de tarjetas

- **Monitoreo y Alertas**
  - CloudWatch para métricas y logs
  - SNS para notificaciones y alertas

## Imagen de Referencia

Mientras generas la imagen real, puedes usar la representación ASCII en `architecture.png.txt` como referencia visual de la arquitectura. 