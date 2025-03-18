# Documentación Detallada del Proyecto de Detección de Fraude

## 0. Diagrama de Arquitectura
```
                                                     +------------------------+
                                                     |     Amazon SNS        |
                                                     | (Alertas de Fraude)   |
                                                     +------------------------+
                                                              ^
                                                              |
+----------------+     +---------------+     +----------------+ |   +------------------+
|   Kaggle API   |     |  AWS Lambda   |     | Amazon S3      | |   |  AWS Lambda      |
| (Dataset Fraud)|---->| (Downloader)  |---->| (Raw Zone)     | |   | (Data Quality)   |
+----------------+     +---------------+     +----------------+ |   +------------------+
                                                  |           |            |
                                                  v           |            v
                                           +----------------+ |     +------------------+
                                           |   AWS Glue     | |     |  Amazon Kinesis |
                                           | (ETL Process)  | |     | (Stream Process)|
                                           +----------------+ |     +------------------+
                                                  |           |            |
                                                  v           |            v
                                           +----------------+ |     +------------------+
                                           | Amazon S3      | |     |   DynamoDB      |
                                           |(Processed Zone)| |     |(Card Statistics)|
                                           +----------------+ |     +------------------+
                                                  |           |
                                                  v           |
                                           +----------------+ |
                                           | Amazon S3      | |
                                           |(Analytics Zone)|-+
                                           +----------------+
                                                  |
                                    +-------------+-------------+
                                    |                           |
                                    v                           v
                              +----------+               +-----------+
                              | Redshift |               |  Athena   |
                              |(Análisis)|               |(Queries)  |
                              +----------+               +-----------+
                                    |                           |
                                    +-------------+-------------+
                                                |
                                                v
                                          +----------+
                                          |QuickSight|
                                          |(Dashboards)
                                          +----------+
```

## 1. Visión General de la Arquitectura

### 1.1 Componentes Principales
El proyecto implementa una arquitectura serverless para la detección de fraude financiero, utilizando los siguientes componentes principales:

- **Ingesta de Datos**: AWS Lambda + Kaggle API
- **Almacenamiento**: Amazon S3 (3 capas: raw, processed, analytics)
- **Procesamiento**: AWS Glue + AWS Lambda + Kinesis
- **Análisis**: Amazon Redshift + Amazon Athena
- **Monitoreo**: Amazon CloudWatch
- **Seguridad**: IAM + Security Groups + VPC Endpoints

### 1.2 Flujo de Datos
1. Ingesta desde Kaggle mediante Lambda programada
2. Almacenamiento en S3 raw
3. Procesamiento batch con Glue
4. Procesamiento en tiempo real con Kinesis + Lambda
5. Análisis con Redshift/Athena
6. Visualización con QuickSight

## 1.3 Pipeline de Datos Detallado

### Fase 1: Ingesta de Datos
1. **Descarga desde Kaggle**
   - Frecuencia: Diaria (configurable)
   - Formato: CSV
   - Lambda function con Kaggle API
   - Almacenamiento en S3 raw con particionamiento por fecha

2. **Validación Inicial**
   - Verificación de estructura
   - Comprobación de tipos de datos
   - Detección de valores nulos
   - Logging de errores en CloudWatch

### Fase 2: Procesamiento Batch
1. **ETL con Glue**
   ```python
   # Ejemplo de transformaciones
   - Normalización de campos
   - Feature engineering
   - Agregaciones temporales
   - Detección de anomalías
   ```

2. **Almacenamiento Procesado**
   - Formato: Parquet (columnar)
   - Particionamiento por fecha/categoría
   - Compresión para optimización

### Fase 3: Procesamiento Real-time
1. **Ingesta Kinesis**
   ```json
   {
     "transaction_id": "123",
     "amount": 1000.00,
     "merchant": "Store XYZ",
     "timestamp": "2024-03-16T12:00:00Z"
   }
   ```

2. **Procesamiento Lambda**
   - Validación en tiempo real
   - Scoring de fraude
   - Actualización de estadísticas

3. **Almacenamiento DynamoDB**
   ```json
   {
     "card_id": "456",
     "stats": {
       "total_transactions": 100,
       "avg_amount": 500.00,
       "risk_score": 0.85
     }
   }
   ```

### Fase 4: Análisis
1. **Queries Athena**
   ```sql
   SELECT 
     DATE(timestamp) as date,
     COUNT(*) as transactions,
     SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count
   FROM transactions
   GROUP BY DATE(timestamp)
   ```

2. **Análisis Redshift**
   - Queries complejos
   - Joins con dimensiones
   - Agregaciones históricas

### Fase 5: Visualización
1. **Dashboards QuickSight**
   - KPIs de fraude
   - Tendencias temporales
   - Mapas de calor
   - Alertas visuales

## 1.4 Optimizaciones Implementadas

### Performance
1. **S3**
   - Particionamiento optimizado
   - Formato columnar (Parquet)
   - Lifecycle policies

2. **Glue**
   - Pushdown predicates
   - Job bookmarks
   - DPU auto-scaling

3. **Kinesis**
   - Enhanced fan-out
   - Retry con exponential backoff
   - Error handling robusto

### Costos
1. **Almacenamiento**
   - Transición automática entre tiers
   - Compresión de datos
   - Limpieza programada

2. **Computación**
   - Serverless donde posible
   - Auto-scaling configurado
   - Optimización de recursos

### Monitoreo
1. **Métricas Clave**
   - Latencia de procesamiento
   - Tasa de error
   - Uso de recursos
   - Costos por componente

2. **Alertas**
   - Umbrales configurables
   - Notificaciones SNS
   - Escalamiento automático

## 2. Módulos del Proyecto

### 2.1 Módulo de Ingesta (data_ingestion)
```terraform
# Componentes principales:
- Lambda Function para descarga de Kaggle
- Lambda Layer con dependencias de Kaggle
- EventBridge para programación
- IAM roles y políticas
```

#### Detalles Técnicos:
- Función Lambda con Python 3.9
- Autenticación con Kaggle mediante variables de entorno
- Organización de datos por fecha en S3
- Manejo de errores y logging

### 2.2 Módulo de Almacenamiento (storage)
```terraform
# Características principales:
- Buckets S3 para cada capa (raw, processed, analytics)
- Lifecycle policies para optimización de costos
- Encriptación por defecto
- Bloqueo de acceso público
```

#### Políticas de Lifecycle:
- **Raw**: 
  - Transición a IA: 30 días
  - Transición a Glacier: 90 días
  - Expiración: 365 días
- **Processed**:
  - Transición a IA: 60 días
  - Transición a Glacier: 180 días
  - Expiración: 730 días

### 2.3 Módulo de Procesamiento (processing)
```terraform
# Componentes clave:
- Glue Database y Crawler
- Glue ETL Job
- Kinesis Data Stream
- DynamoDB para estadísticas
- Funciones Lambda para validación y procesamiento
```

#### Pipeline de Procesamiento:
1. **Validación de Datos**:
   - Lambda function para quality checks
   - Verificación de esquema y valores
   - Logging de errores

2. **Procesamiento Batch**:
   - Glue Job para transformación
   - Agregaciones y feature engineering
   - Exportación a formato Parquet

3. **Procesamiento Real-time**:
   - Kinesis stream para ingesta
   - Lambda para detección en tiempo real
   - Actualización de DynamoDB

### 2.4 Módulo de Analytics (analytics)
```terraform
# Componentes principales:
- Cluster Redshift (en prod)
- Athena Workgroup y Queries
- Glue Catalog Database
- QuickSight integration
```

#### Capacidades Analíticas:
- Queries predefinidos para análisis de fraude
- Integración con S3 para resultados
- Optimización de costos con particionamiento

### 2.5 Módulo de Seguridad (security)
```terraform
# Implementaciones:
- IAM roles específicos por servicio
- Security Groups
- VPC Endpoints
- Encryption in-transit y at-rest
```

#### Roles IAM:
- Glue Role: Acceso a S3, Glue, CloudWatch
- Lambda Role: Acceso a S3, DynamoDB, Kinesis
- Redshift Role: Acceso a S3, CloudWatch
- QuickSight Role: Acceso a Athena, S3

### 2.6 Módulo de Monitoreo (monitoring)
```terraform
# Características:
- CloudWatch Logs
- CloudWatch Metrics
- SNS Topics para alertas
- Dashboard personalizado
```

## 3. Configuración y Despliegue

### 3.1 Variables de Entorno
```terraform
# Principales variables:
- project_name
- environment
- region
- VPC/Subnet IDs
- Credenciales (Kaggle, Redshift)
```

### 3.2 Proceso de Despliegue
1. Inicialización de Terraform
2. Validación de configuración
3. Planificación de recursos
4. Aplicación de cambios
5. Verificación de recursos

## 4. Mejores Prácticas Implementadas

### 4.1 Seguridad
- Encriptación end-to-end
- Principio de mínimo privilegio
- Aislamiento de red
- Rotación de credenciales

### 4.2 Costos
- Lifecycle policies
- Serverless cuando es posible
- Optimización de recursos
- Monitoreo de uso

### 4.3 Operaciones
- Logging centralizado
- Monitoreo proactivo
- Automatización de tareas
- Backup y recuperación

## 5. Puntos de Extensión

### 5.1 Escalabilidad
- Ajuste de Kinesis shards
- Configuración de concurrencia Lambda
- Escalado de Redshift
- Optimización de Glue jobs

### 5.2 Nuevas Funcionalidades
- Modelos ML adicionales
- APIs para integración
- Dashboards personalizados
- Exportación de datos

## 6. Mantenimiento y Operación

### 6.1 Tareas Diarias
- Monitoreo de jobs
- Verificación de logs
- Validación de datos
- Respuesta a alertas

### 6.2 Tareas Periódicas
- Optimización de costos
- Actualización de dependencias
- Review de seguridad
- Backup verification

## 7. Troubleshooting

### 7.1 Problemas Comunes
1. Fallos en ingesta de datos
2. Errores de procesamiento
3. Problemas de permisos
4. Issues de rendimiento

### 7.2 Soluciones
- Verificación de logs
- Validación de IAM
- Revisión de configuración
- Ajuste de recursos

## 8. Métricas de Éxito

### 8.1 Operacionales
- Uptime del sistema
- Tiempo de procesamiento
- Tasa de errores
- Latencia de detección

### 8.2 Negocio
- Tasa de detección de fraude
- Falsos positivos/negativos
- Tiempo de respuesta
- Ahorro en prevención

## 9. Próximos Pasos

### 9.1 Mejoras Técnicas
- Implementación de CI/CD
- Optimización de costos
- Mejora de modelos ML
- Enhanced monitoring

### 9.2 Funcionalidades
- API REST
- UI para análisis
- Reportes automáticos
- Integración con sistemas externos

## 10. Guía de Implementación

### 10.1 Requisitos Previos
1. **AWS CLI configurado**
   ```bash
   aws configure
   # AWS Access Key ID: YOUR_ACCESS_KEY
   # AWS Secret Access Key: YOUR_SECRET_KEY
   # Default region name: us-east-1
   ```

2. **Terraform instalado**
   ```bash
   # Verificar instalación
   terraform version
   # Debe ser >= 1.0
   ```

3. **Python y dependencias**
   ```bash
   # Crear entorno virtual
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   .\venv\Scripts\activate   # Windows
   
   # Instalar dependencias
   pip install -r requirements.txt
   ```

### 10.2 Configuración Inicial

1. **Variables de Entorno**
   ```bash
   # Crear archivo .env
   KAGGLE_USERNAME=your_username
   KAGGLE_KEY=your_key
   TF_VAR_alert_email=your@email.com
   ```

2. **Terraform Variables**
   ```hcl
   # terraform.tfvars
   project_name = "fraud-detection"
   environment  = "dev"
   region       = "us-east-1"
   vpc_id       = "vpc-xxxxx"
   subnet_ids   = ["subnet-xxxxx", "subnet-yyyyy"]
   ```

### 10.3 Pasos de Despliegue

1. **Inicialización**
   ```bash
   # Inicializar Terraform
   terraform init
   
   # Verificar formato
   terraform fmt
   
   # Validar configuración
   terraform validate
   ```

2. **Plan y Aplicación**
   ```bash
   # Generar plan
   terraform plan -out=tfplan
   
   # Aplicar cambios
   terraform apply tfplan
   ```

3. **Verificación**
   ```bash
   # Listar recursos
   terraform state list
   
   # Verificar outputs
   terraform output
   ```

### 10.4 Post-Despliegue

1. **Verificación de Recursos**
   ```bash
   # Verificar buckets S3
   aws s3 ls
   
   # Verificar funciones Lambda
   aws lambda list-functions
   
   # Verificar jobs de Glue
   aws glue get-jobs
   ```

2. **Configuración de Monitoreo**
   ```bash
   # Verificar grupos de logs
   aws logs describe-log-groups
   
   # Verificar métricas
   aws cloudwatch list-metrics
   ```

3. **Pruebas Iniciales**
   ```bash
   # Trigger Lambda de ingesta
   aws lambda invoke \
     --function-name fraud-detection-dev-kaggle-downloader \
     --payload '{}' \
     response.json
   
   # Verificar datos en S3
   aws s3 ls s3://fraud-detection-dev-raw/
   ```

### 10.5 Mantenimiento

1. **Backup**
   ```bash
   # Backup de estado
   terraform state pull > backup.tfstate
   
   # Backup de configuración
   zip -r config_backup.zip *.tf *.tfvars
   ```

2. **Actualizaciones**
   ```bash
   # Actualizar providers
   terraform init -upgrade
   
   # Aplicar cambios
   terraform apply
   ```

3. **Limpieza**
   ```bash
   # Destruir recursos (¡Usar con precaución!)
   terraform destroy
   
   # Limpiar archivos locales
   rm -rf .terraform/
   rm terraform.tfstate*
   ```

### 10.6 Troubleshooting

1. **Problemas Comunes**
   ```bash
   # Error de credenciales
   aws sts get-caller-identity
   
   # Error de permisos
   aws iam get-user
   
   # Verificar logs
   aws logs tail /aws/lambda/fraud-detection-dev-kaggle-downloader
   ```

2. **Debugging**
   ```bash
   # Habilitar logs detallados
   export TF_LOG=DEBUG
   
   # Verificar estado
   terraform show
   
   # Refrescar estado
   terraform refresh
   ```

### 10.7 Comandos Útiles

1. **Terraform**
   ```bash
   # Formatear todos los archivos
   terraform fmt -recursive
   
   # Listar providers
   terraform providers
   
   # Verificar workspace
   terraform workspace show
   ```

2. **AWS**
   ```bash
   # Verificar VPC
   aws ec2 describe-vpcs
   
   # Listar subnets
   aws ec2 describe-subnets
   
   # Verificar security groups
   aws ec2 describe-security-groups
   ```

3. **Monitoreo**
   ```bash
   # Verificar métricas personalizadas
   aws cloudwatch list-metrics \
     --namespace "FraudDetection"
   
   # Obtener logs recientes
   aws logs get-log-events \
     --log-group-name "/aws/lambda/fraud-detection-dev-kaggle-downloader" \
     --log-stream-name "$(date +%Y/%m/%d)"
   ``` 