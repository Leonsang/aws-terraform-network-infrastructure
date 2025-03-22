#!/bin/bash
set -e

# Obtener argumentos
account=$(aws sts get-caller-identity --query Account --output text)
region=${1:-us-east-1}
tag=${2:-latest}

# Obtener el login de ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account}.dkr.ecr.${region}.amazonaws.com

# Crear el repositorio si no existe
repo_name="fraud-detection-training"
aws ecr describe-repositories --repository-names ${repo_name} --region ${region} || \
    aws ecr create-repository --repository-name ${repo_name} --region ${region}

# Construir la imagen
docker build -t ${repo_name} .
fullname="${account}.dkr.ecr.${region}.amazonaws.com/${repo_name}:${tag}"
docker tag ${repo_name} ${fullname}

# Subir la imagen
docker push ${fullname}

# Limpiar imágenes locales
docker rmi ${repo_name}
docker rmi ${fullname}

echo "Imagen subida exitosamente: ${fullname}" 