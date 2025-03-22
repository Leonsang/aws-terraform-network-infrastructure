#!/bin/bash
set -e

# Crear estructura de directorios
mkdir -p python
cd python

# Instalar dependencias
pip install -r ../requirements.txt -t .

# Crear archivo zip
cd ..
zip -r kaggle_layer.zip python/

# Limpiar
rm -rf python/

echo "Capa Lambda construida exitosamente como kaggle_layer.zip" 