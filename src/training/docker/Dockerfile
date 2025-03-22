FROM python:3.8-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar directorios de SageMaker
RUN mkdir -p /opt/ml/model \
    /opt/ml/input/data/training \
    /opt/ml/input/config \
    /opt/ml/code

# Copiar scripts al contenedor
COPY train.py /opt/ml/code/
COPY inference.py /opt/ml/code/

# Instalar dependencias de Python
RUN pip install --no-cache-dir \
    pandas==2.0.3 \
    numpy==1.24.3 \
    scikit-learn==1.3.0 \
    lightgbm==4.0.0 \
    joblib==1.3.1 \
    boto3==1.26.137

# Configurar variables de entorno
ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/ml/code:${PATH}"

# Establecer directorio de trabajo
WORKDIR /opt/ml/code

# Punto de entrada para entrenamiento
ENTRYPOINT ["python", "train.py"] 