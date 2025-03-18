# Estructura del Proyecto

Este documento detalla la estructura de directorios y archivos del proyecto de detección de fraude financiero.

## Estructura Principal

```
.
├── modules/                # Módulos de Terraform
│   ├── analytics/          # Módulo para Redshift, Athena
│   ├── monitoring/         # Módulo para CloudWatch, SNS
│   ├── processing/         # Módulo para Glue, Lambda, Kinesis
│   ├── security/           # Módulo para IAM roles y políticas
│   └── storage/            # Módulo para S3 buckets
├── scripts/                # Scripts para Glue y Lambda
│   ├── glue/               # Scripts de ETL para Glue
│   └── lambda/             # Funciones Lambda
├── .gitignore              # Archivos a ignorar por Git
├── CUMPLIMIENTO_PRUEBA_TECNICA.md  # Documentación de cumplimiento
├── ContextoPBTecnica.md    # Contexto de la prueba técnica
├── ESTRUCTURA_PROYECTO.md  # Este archivo
├── INSTRUCCIONES_GIT.md    # Instrucciones para Git
├── LICENSE                 # Licencia MIT
├── README.md               # Documentación principal
├── main.tf                 # Archivo principal de Terraform
├── outputs.tf              # Salidas del proyecto
├── terraform.tfvars        # Valores de las variables
└── variables.tf            # Definición de variables
```

## Detalle de Módulos

### Módulo de Almacenamiento (storage)

```
modules/storage/
├── main.tf                 # Definición de buckets S3
├── variables.tf            # Variables del módulo
└── outputs.tf              # Salidas del módulo
```

### Módulo de Procesamiento (processing)

```
modules/processing/
├── main.tf                 # Definición de recursos de procesamiento
├── variables.tf            # Variables del módulo
└── outputs.tf              # Salidas del módulo
```

### Módulo de Analítica (analytics)

```
modules/analytics/
├── main.tf                 # Definición de recursos de analítica
├── variables.tf            # Variables del módulo
└── outputs.tf              # Salidas del módulo
```

### Módulo de Seguridad (security)

```
modules/security/
├── main.tf                 # Definición de roles y políticas IAM
├── variables.tf            # Variables del módulo
└── outputs.tf              # Salidas del módulo
```

### Módulo de Monitoreo (monitoring)

```
modules/monitoring/
├── main.tf                 # Definición de recursos de monitoreo
├── variables.tf            # Variables del módulo
└── outputs.tf              # Salidas del módulo
```

## Scripts

### Scripts de Glue

```
scripts/glue/
└── etl_job.py              # Script ETL para procesamiento por lotes
```

### Scripts de Lambda

```
scripts/lambda/
├── data_quality_lambda.py  # Función para validación de calidad
└── realtime_fraud_lambda.py # Función para detección en tiempo real
```

## Archivos de Configuración

- **main.tf**: Archivo principal que define la estructura del proyecto y llama a los módulos
- **variables.tf**: Define todas las variables utilizadas en el proyecto
- **outputs.tf**: Define las salidas del proyecto
- **terraform.tfvars**: Contiene los valores de las variables

## Documentación

- **README.md**: Documentación principal del proyecto
- **CUMPLIMIENTO_PRUEBA_TECNICA.md**: Detalla cómo el proyecto cumple con los requisitos
- **ContextoPBTecnica.md**: Contiene el contexto original de la prueba técnica
- **ESTRUCTURA_PROYECTO.md**: Este archivo que documenta la estructura
- **INSTRUCCIONES_GIT.md**: Instrucciones para configurar Git y subir a GitHub
- **LICENSE**: Licencia MIT del proyecto 