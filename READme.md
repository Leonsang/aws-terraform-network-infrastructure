# 🛡️ Proyecto de Detección de Fraude Financiero con Terraform

[![AWS](https://img.shields.io/badge/AWS-Powered-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-v1.2.0+-blueviolet)](https://www.terraform.io/)
[![Kaggle](https://img.shields.io/badge/Dataset-Kaggle-blue)](https://www.kaggle.com/c/ieee-fraud-detection)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-green)](LICENSE)

Este proyecto implementa un sistema de ingeniería de datos para detección de fraude financiero en AWS, utilizando Terraform para la infraestructura como código. El sistema está diseñado siguiendo una arquitectura Lakehouse con tres zonas de datos y utiliza Athena para consultas SQL sobre datos en S3.

> **Nota sobre la Arquitectura Actual**: Para la implementación inicial y pruebas, estamos utilizando una versión optimizada para la capa gratuita de AWS. Sin embargo, el proyecto está diseñado para escalar a una arquitectura completa de producción cuando sea necesario.

## 📋 Tabla de Contenidos

- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Dataset](#-dataset)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Guía de Instalación](#-guía-de-instalación)
- [Componentes Principales](#-componentes-principales)
- [Costos y Límites](#-costos-y-límites)
- [Documentación Detallada](#-documentación-detallada)
- [Solución de Problemas](#-solución-de-problemas)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)
- [Contacto](#-contacto)

## 🏗️ Arquitectura del Sistema

El sistema sigue una arquitectura Lakehouse en AWS con tres zonas principales:

### Raw Zone (Bronze) 🥉

- **Propósito**: Almacenamiento de datos sin procesar
- **Implementación**: Bucket S3 con catalogación mediante Glue Crawler
- **Formato**: Original (CSV) o Parquet con compresión
- **Características**: Inmutabilidad, retención configurable, particionamiento por fecha

### Processed Zone (Silver) 🥈

- **Propósito**: Datos limpios y transformados
- **Implementación**: Bucket S3 con modelo estrella implementado
- **Procesamiento**: ETL gestionado con AWS Glue
- **Características**: Validación de calidad, normalización, enriquecimiento

### Analytics Zone (Gold) 🥇

- **Propósito**: Vistas materializadas para análisis
- **Implementación**:
  - **Athena**: Consultas SQL sobre datos en S3
  - **Vistas Materializadas**: Optimizadas para consultas frecuentes
  - **Métricas**: Dashboard de KPIs de fraude
- **Características**:
  - Optimización para consultas SQL
  - Particionamiento inteligente
  - Compresión de datos
  - Cache de consultas frecuentes

### Flujo de Datos

```
Ingesta → Raw Zone → Procesamiento → Processed Zone → Análisis → Analytics Zone
   ↑                     ↑                                 ↓
Tiempo Real         Batch (Glue)                      Dashboards
(Kinesis)                                            (QuickSight)
                     ↓
                Athena (SQL)
```

## 💰 Costos y Límites

El proyecto está optimizado para la capa gratuita de AWS:

### Servicios Incluidos

- **S3**: 5GB de almacenamiento
- **Lambda**: 1M de invocaciones/mes
- **CloudWatch**: 5GB de logs/mes
- **Glue**: 10,000 DPU-horas/mes
- **Athena**: 1TB de datos escaneados/mes

### Optimizaciones

- Compresión de datos en S3 (Parquet con SNAPPY)
- Particionamiento eficiente por fecha
- Limpieza automática de logs
- Monitoreo de costos
- Cache de consultas frecuentes en Athena
- Vistas materializadas para reducir costos

## 📁 Estructura del Proyecto

```
.
├── infrastructure/           # Infraestructura como código
│   ├── environments/        # Configuraciones por ambiente
│   │   └── dev/            # Ambiente de desarrollo
│   │       ├── main.tf     # Configuración principal
│   │       ├── variables.tf # Variables del ambiente
│   │       ├── outputs.tf   # Outputs del ambiente
│   │       ├── terraform.tfvars # Valores de variables
│   │       └── backend.hcl  # Configuración del backend
│   └── modules/            # Módulos de infraestructura
│       ├── storage/        # Módulo para S3 buckets
│       ├── processing/     # Módulo para Glue, Lambda
│       ├── analytics/      # Módulo para Athena
│       ├── security/       # Módulo para IAM y políticas
│       └── monitoring/     # Módulo para CloudWatch
├── src/                    # Código fuente del proyecto
│   ├── data_ingestion/    # Módulo de ingesta de datos
│   ├── data_processing/   # Módulo de procesamiento
│   ├── model_training/    # Módulo de entrenamiento
│   └── config/           # Archivos de configuración
├── scripts/               # Scripts de utilidad
│   ├── glue/             # Scripts de ETL para Glue
│   ├── lambda/           # Funciones Lambda
│   └── athena/           # Scripts SQL para Athena
├── tests/                # Pruebas unitarias e integración
├── docs/                 # Documentación del proyecto
│   ├── setup/           # Guías de configuración
│   ├── technical/       # Documentación técnica
│   ├── context/         # Contexto del negocio
│   └── diagrams/        # Diagramas del sistema
├── data/                # Datos de ejemplo y pruebas
├── requirements.txt     # Dependencias del proyecto
├── LICENSE             # Licencia del proyecto
└── README.md           # Documentación principal
```

## 🔧 Requisitos Previos

- [Terraform](https://www.terraform.io/downloads.html) v1.2.0 o superior
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales adecuadas
- [Python](https://www.python.org/downloads/) 3.9 o superior (para scripts locales)
- [Cuenta de Kaggle](https://www.kaggle.com/) con API key para descarga automática
- [Git](https://git-scm.com/downloads) para clonar el repositorio
- [AWS Athena](https://aws.amazon.com/athena/) (incluido en la capa gratuita)

## 🚀 Guía de Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/Leonsang/fraud-detection-terraform.git
cd fraud-detection-terraform
```

### 2. Configurar Credenciales de AWS

```bash
export AWS_ACCESS_KEY_ID="tu_access_key"
export AWS_SECRET_ACCESS_KEY="tu_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

En Windows PowerShell:

```powershell
$env:AWS_ACCESS_KEY_ID="tu_access_key"
$env:AWS_SECRET_ACCESS_KEY="tu_secret_key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### 3. Personalizar Variables

Revisa y modifica los valores en `infrastructure/environments/dev/terraform.tfvars` según tus necesidades:

```hcl
# Configuración general
aws_region   = "us-east-1"
project_name = "fraud-detection"
environment  = "dev"  # Cambia a "test" o "prod" según sea necesario

# Configuración de Kaggle
kaggle_username = "tu_usuario_kaggle"  # Reemplazar con tu usuario de Kaggle
kaggle_key      = "tu_api_key_kaggle"  # Reemplazar con tu API key de Kaggle

# Configuración de Athena
athena_database_bucket = "fraud-detection-dev-athena-db"
athena_output_bucket  = "fraud-detection-dev-athena-output"
processed_bucket     = "fraud-detection-dev-processed"
```

### 4. Configurar Credenciales de Kaggle

Para la descarga automática del dataset IEEE-CIS Fraud Detection:

1. Crea una cuenta en [Kaggle](https://www.kaggle.com/) si aún no tienes una
2. Ve a tu perfil > Account > API > Create New API Token
3. Esto descargará un archivo `kaggle.json` con tus credenciales
4. Copia el archivo a `src/config/kaggle.json`
5. Actualiza los valores en `infrastructure/environments/dev/terraform.tfvars`

### 5. Crear la Capa Lambda para Kaggle

```bash
# Navegar al directorio de scripts
cd scripts/lambda

# Dar permisos de ejecución al script (en Linux/Mac)
chmod +x create_kaggle_layer.sh

# Ejecutar el script
./create_kaggle_layer.sh
```

### 6. Inicializar y Aplicar Terraform

```bash
# Navegar al directorio del ambiente de desarrollo
cd infrastructure/environments/dev

# Inicializar Terraform
terraform init

# Crear un plan de ejecución
terraform plan -out=tfplan

# Aplicar la configuración
terraform apply tfplan
```

### 7. Ejecutar la Descarga de Datos Manualmente (opcional)

```bash
# Navegar al directorio de scripts
cd ../../../scripts/lambda

# Dar permisos de ejecución al script (en Linux/Mac)
chmod +x trigger_kaggle_download.sh

# Ejecutar el script
./trigger_kaggle_download.sh fraud-detection-dev-kaggle-downloader
```

### 8. Monitorear el Pipeline

Puedes monitorear el estado del pipeline a través de:

- **AWS Console**:
  - CloudWatch Dashboard
  - Athena Query Editor
  - Glue Jobs
- **CLI**:

  ```bash
  # Ver estado del job de Glue
  aws glue get-job-runs --job-name fraud-detection-dev-etl-job
  
  # Ver logs de la función Lambda
  aws logs get-log-events --log-group-name /aws/lambda/fraud-detection-dev-kaggle-downloader --log-stream-name $(aws logs describe-log-streams --log-group-name /aws/lambda/fraud-detection-dev-kaggle-downloader --query 'logStreams[0].logStreamName' --output text)
  
  # Ver consultas de Athena
  aws athena list-query-executions --work-group fraud-detection-dev-workgroup
  ```

### 9. Destruir la Infraestructura (cuando ya no se necesite)

```bash
terraform destroy
```

## 🧩 Componentes Principales

### Módulos de Infraestructura 🏗️

#### Storage (`infrastructure/modules/storage/`) 💾

- **Data Lake (S3)**
  - Zonas Raw, Processed y Analytics
  - Lifecycle policies por tipo de dato
  - Compresión y particionamiento inteligente
  - Integración con AWS Lake Formation

#### Analytics (`infrastructure/modules/analytics/`) 📊

- **Athena**
  - Workgroup para ejecución de consultas
  - Base de datos y tablas externas
  - Vistas materializadas
  - Políticas de IAM
  - Monitoreo con CloudWatch

#### Processing (`infrastructure/modules/processing/`) ⚙️

- **Glue Jobs**
  - ETL de datos raw a processed
  - Transformaciones de datos
  - Particionamiento automático
  - Monitoreo de ejecución

- **Lambda Functions**
  - Descarga de datos de Kaggle
  - Procesamiento en tiempo real
  - Triggers de ETL

## 🔍 Solución de Problemas

### Problemas Comunes

1. **Error de Permisos en Athena**

   ```bash
   # Verificar políticas IAM
   aws iam get-role --role-name fraud-detection-dev-athena-role
   
   # Verificar permisos S3
   aws s3 ls s3://fraud-detection-dev-processed/
   ```

2. **Consultas Lentas en Athena**
   - Verificar particionamiento de tablas
   - Optimizar formato de datos (Parquet)
   - Revisar estadísticas de tablas

3. **Errores en Glue Jobs**

   ```bash
   # Ver logs detallados
   aws glue get-job-run --job-name fraud-detection-dev-etl-job --run-id <run-id>
   ```

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Contacto

Tu Nombre - [@tutwitter](https://twitter.com/tutwitter) - <email@example.com>

Link del Proyecto: [https://github.com/Leonsang/fraud-detection-terraform](https://github.com/Leonsang/fraud-detection-terraform)

## 📊 Notebooks y Análisis Prácticos

### 1. Análisis Exploratorio 🔍

#### Notebook: `notebooks/01_exploratory/fraud_patterns.ipynb`

```python
# Análisis de patrones de fraude
import pandas as pd
import plotly.express as px
from awswrangler import s3

# Cargar datos de diferentes fuentes
transactions = s3.read_parquet("s3://fraud-detection/processed/transactions/")
identity = s3.read_parquet("s3://fraud-detection/processed/identity/")
crypto = s3.read_parquet("s3://fraud-detection/processed/crypto/")

# Análisis de correlaciones
correlation_matrix = px.imshow(transactions.corr())
correlation_matrix.show()

# Análisis temporal de fraudes
fraud_timeline = px.line(transactions.groupby('date')['is_fraud'].mean())
fraud_timeline.show()
```

### 2. Feature Engineering 🛠️

#### Notebook: `notebooks/02_features/feature_creation.ipynb`

```python
# Creación de features avanzados
from fraud_detection.features import create_transaction_features
from fraud_detection.features import create_identity_features

# Features basados en ventanas temporales
transaction_features = create_transaction_features(
    transactions,
    windows=[1, 3, 7, 30],  # días
    aggregations=['mean', 'std', 'max']
)

# Features de redes
identity_features = create_identity_features(
    transactions,
    identity,
    network_params={
        'min_transactions': 3,
        'time_window_days': 30
    }
)
```

### 3. Modelado con SageMaker 🤖

#### Notebook: `notebooks/03_modeling/model_training.ipynb`

```python
# Entrenamiento del modelo
import sagemaker
from sagemaker.xgboost import XGBoost

# Configurar hiperparámetros
hyperparameters = {
    'max_depth': 6,
    'eta': 0.3,
    'gamma': 4,
    'min_child_weight': 6,
    'subsample': 0.8,
    'objective': 'binary:logistic',
    'num_round': 100
}

# Crear y entrenar el modelo
xgb_model = XGBoost(
    entry_point='train.py',
    framework_version='1.5-1',
    hyperparameters=hyperparameters,
    role=role,
    instance_count=1,
    instance_type='ml.m5.xlarge'
)

xgb_model.fit({
    'train': 's3://fraud-detection/train',
    'validation': 's3://fraud-detection/validation'
})
```

### 4. Evaluación y Monitoreo 📈

#### Notebook: `notebooks/04_evaluation/model_evaluation.ipynb`

```python
# Evaluación del modelo
from sklearn.metrics import classification_report
import matplotlib.pyplot as plt
import seaborn as sns

# Matriz de confusión
cm = confusion_matrix(y_test, predictions)
sns.heatmap(cm, annot=True, fmt='d')
plt.show()

# Curva ROC
roc_curve = px.line(
    x=fpr, y=tpr,
    title='Curva ROC',
    labels={'x': 'Tasa de Falsos Positivos', 'y': 'Tasa de Verdaderos Positivos'}
)
roc_curve.show()

# Feature Importance
feature_importance = px.bar(
    x=feature_names,
    y=model.feature_importances_,
    title='Importancia de Features'
)
feature_importance.show()
```

### 5. Análisis de Datos No Estructurados 📝

#### Notebook: `notebooks/05_unstructured/document_analysis.ipynb`
