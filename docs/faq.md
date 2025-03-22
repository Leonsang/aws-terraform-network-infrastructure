# ❓ Preguntas Frecuentes

## 🔧 Configuración y Requisitos

### ¿Qué requisitos necesito para ejecutar el proyecto?
- Python 3.9 o superior
- Terraform 1.2.0 o superior
- AWS CLI v2.x
- Cuenta de AWS con acceso a los servicios necesarios
- Cuenta de Kaggle para descargar el dataset

### ¿Cómo configuro las credenciales de AWS?
1. Instala AWS CLI
2. Ejecuta `aws configure`
3. Ingresa tu Access Key ID
4. Ingresa tu Secret Access Key
5. Selecciona tu región (por defecto: us-east-1)

### ¿Cómo obtengo las credenciales de Kaggle?
1. Crea una cuenta en [Kaggle](https://www.kaggle.com)
2. Ve a "Account" → "Create New API Token"
3. Descarga el archivo `kaggle.json`
4. Colócalo en `src/config/kaggle.json`

## 🚀 Despliegue y Ejecución

### ¿Cómo despliego la infraestructura?
```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### ¿Cómo ejecuto el pipeline ETL?
```bash
cd scripts/etl
./run_etl.bat
```

### ¿Cómo monitoreo el progreso?
- Revisa los logs en CloudWatch
- Verifica el estado en Step Functions
- Consulta las métricas en CloudWatch

## 💾 Datos y Almacenamiento

### ¿Dónde se almacenan los datos?
- Raw Zone: `s3://<project-name>-<env>-raw/`
- Processed Zone: `s3://<project-name>-<env>-processed/`
- Analytics Zone: `s3://<project-name>-<env>-analytics/`

### ¿Cómo se manejan los datos sensibles?
- Encriptación en tránsito con TLS
- Encriptación en reposo con KMS
- Políticas de IAM restrictivas

## 🔍 Monitoreo y Mantenimiento

### ¿Cómo monitoreo los costos?
- Revisa el dashboard de costos en AWS
- Configura alertas de presupuesto
- Utiliza el módulo de costos de Terraform

### ¿Cómo actualizo el proyecto?
1. Actualiza las dependencias en `requirements.txt`
2. Ejecuta `terraform init -upgrade`
3. Revisa los cambios con `terraform plan`
4. Aplica los cambios con `terraform apply`

## 🐛 Solución de Problemas

### ¿Qué hago si el despliegue falla?
1. Revisa los logs de Terraform
2. Verifica las credenciales
3. Comprueba los límites de AWS
4. Consulta la documentación de troubleshooting

### ¿Cómo limpio los recursos si algo falla?
```bash
cd infrastructure/environments/dev
terraform destroy
```

## 📊 Análisis y Visualización

### ¿Cómo accedo a los datos procesados?
- Usa Athena para consultas SQL
- Accede a los notebooks en `notebooks/`
- Utiliza QuickSight para visualizaciones

### ¿Cómo interpreto los resultados?
- Revisa la documentación de métricas
- Consulta los dashboards predefinidos
- Analiza los notebooks de ejemplo 