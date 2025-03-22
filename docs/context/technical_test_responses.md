# Respuestas al Test Técnico

## Objetivo del Proyecto

El objetivo principal es desarrollar un sistema de detección de fraude en transacciones financieras utilizando técnicas de análisis de datos y machine learning. El sistema debe ser capaz de:

- Procesar grandes volúmenes de datos de transacciones
- Identificar patrones de comportamiento fraudulento
- Proporcionar alertas en tiempo real
- Generar insights para la toma de decisiones

## Preguntas de Análisis

1. ¿Cuáles son los patrones temporales más comunes en transacciones fraudulentas?
2. ¿Qué características son más importantes para identificar fraudes?
3. ¿Cómo varía la tasa de fraude por categoría de comerciante?
4. ¿Cuál es la distribución de montos en transacciones fraudulentas vs legítimas?
5. ¿Cómo podemos mejorar la detección temprana de fraudes?

## Justificación del Modelo

Se eligió un modelo basado en AWS Athena por las siguientes razones:

1. **Escalabilidad**: Puede manejar grandes volúmenes de datos sin necesidad de infraestructura adicional
2. **Costo-efectividad**: Solo se paga por los datos escaneados
3. **Integración**: Se integra perfectamente con otros servicios AWS
4. **Flexibilidad**: Permite consultas SQL sobre datos en S3
5. **Mantenibilidad**: No requiere gestión de servidores

## Escenarios de Escalabilidad

### 1. Datos 100x más grandes

**Cambios propuestos:**

- Implementar particionamiento en S3 por fecha
- Utilizar formatos de archivo optimizados (Parquet)
- Implementar caché de consultas frecuentes
- Aumentar recursos de Glue para procesamiento paralelo

### 2. Tuberías diarias en ventana específica

**Cambios propuestos:**

- Implementar AWS EventBridge para programación
- Añadir monitoreo de ventanas de tiempo
- Implementar retry policies
- Añadir notificaciones de estado

### 3. Acceso de 100+ usuarios

**Cambios propuestos:**

- Implementar AWS IAM roles específicos
- Añadir políticas de acceso granular
- Implementar caché de consultas
- Monitorear uso de recursos

### 4. Analítica en tiempo real

**Cambios propuestos:**

- Implementar Amazon Kinesis para streaming
- Añadir Amazon DynamoDB para datos en tiempo real
- Implementar AWS Lambda para procesamiento
- Utilizar Amazon QuickSight para visualización

## Criterios de Reproducibilidad

1. **Infraestructura como Código**
   - Todo el código de infraestructura está en Terraform
   - Scripts de despliegue automatizados
   - Documentación detallada de requisitos

2. **Datos**
   - Dataset público de Kaggle
   - Scripts de descarga y procesamiento
   - Documentación de estructura de datos

3. **Análisis**
   - Notebooks Jupyter con código ejecutable
   - Documentación de pasos de análisis
   - Resultados reproducibles

4. **Control de Calidad**
   - Tests automatizados
   - Validación de datos
   - Monitoreo de calidad
