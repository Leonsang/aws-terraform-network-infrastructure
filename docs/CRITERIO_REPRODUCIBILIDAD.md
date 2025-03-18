# 🔄 Criterios de Reproducibilidad

Este documento establece los criterios y pasos necesarios para garantizar la reproducibilidad del proyecto de detección de fraude financiero.

## 🎯 Objetivos

1. Garantizar que el proyecto pueda ser reproducido en cualquier entorno compatible
2. Establecer estándares de versionado y dependencias
3. Documentar requisitos específicos de configuración
4. Definir procesos de validación

## 📋 Requisitos de Versiones

### Software Base
- **Sistema Operativo**: Windows 10/11, Linux (Ubuntu 20.04+), macOS (Catalina+)
- **Python**: 3.9.x
- **Terraform**: 1.2.0+
- **AWS CLI**: v2.x
- **Git**: 2.x+

### Dependencias AWS
- **Provider AWS**: ~> 4.0
- **Lambda Runtime**: Python 3.9
- **Glue Version**: 3.0
- **Spark Version**: 3.1.1

### Paquetes Python
```requirements.txt
boto3~=1.26.0
pandas~=1.5.0
numpy~=1.23.0
kaggle~=1.5.12
pyarrow~=9.0.0
```

## 🔧 Configuración del Entorno

### 1. Variables de Entorno Requeridas
```bash
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
KAGGLE_USERNAME
KAGGLE_KEY
```

### 2. Estructura de Directorios
```
fraud-detection-terraform/
├── modules/
│   ├── analytics/
│   ├── data_ingestion/
│   ├── monitoring/
│   ├── processing/
│   ├── security/
│   └── storage/
├── scripts/
│   ├── glue/
│   ├── lambda/
│   └── utils/
└── docs/
```

### 3. Archivos de Configuración
- `terraform.tfvars` (variables del proyecto)
- `kaggle.json` (credenciales de Kaggle)
- `.gitignore` (exclusiones de Git)

## 📊 Datos

### Dataset Principal
- **Nombre**: IEEE-CIS Fraud Detection
- **Versión**: 2019
- **Formato**: CSV
- **Tamaño**: ~1GB
- **Estructura**:
  - `train_transaction.csv`
  - `train_identity.csv`

### Validación de Datos
1. Verificación de esquema
2. Control de tipos de datos
3. Validación de rangos
4. Detección de valores nulos

## 🚀 Proceso de Reproducción

### 1. Preparación
```bash
# Clonar repositorio
git clone https://github.com/Leonsang/fraud-detection-terraform.git
cd fraud-detection-terraform

# Configurar entorno
copy terraform.tfvars.example terraform.tfvars
copy kaggle.json.example kaggle.json
```

### 2. Validación
```bash
# Verificar versiones
python --version
terraform --version
aws --version

# Validar configuración
terraform init
terraform validate
```

### 3. Despliegue
```bash
# Desplegar infraestructura
terraform apply -auto-approve

# Verificar recursos
aws s3 ls
aws lambda list-functions
```

## 🔍 Verificación

### 1. Pruebas Automatizadas
```bash
# Ejecutar pruebas
python -m pytest tests/
```

### 2. Validaciones Manuales
1. Verificar buckets S3
2. Confirmar funciones Lambda
3. Validar jobs de Glue
4. Comprobar métricas CloudWatch

## 📈 Métricas de Éxito

### Criterios de Validación
1. ✅ Infraestructura desplegada correctamente
2. ✅ Pipeline de datos funcionando
3. ✅ Logs y métricas disponibles
4. ✅ Datos procesados correctamente

### Umbrales de Calidad
1. Cobertura de pruebas > 80%
2. Tiempo de despliegue < 30 minutos
3. Tasa de error < 1%
4. Latencia de procesamiento < 5 minutos

## 🔄 Mantenimiento

### Actualizaciones Periódicas
1. Revisar versiones de dependencias
2. Actualizar AMIs de Glue
3. Rotar credenciales
4. Actualizar documentación

### Monitoreo Continuo
1. Revisar métricas CloudWatch
2. Verificar logs de errores
3. Validar integridad de datos
4. Comprobar costos AWS

## 📞 Soporte

### Canales de Ayuda
1. Issues en GitHub
2. Documentación técnica
3. Equipo de desarrollo

### Problemas Comunes
1. Errores de permisos
2. Problemas de red
3. Límites de AWS
4. Errores de datos 