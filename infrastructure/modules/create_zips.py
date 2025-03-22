import os
import zipfile
import shutil

def create_zip(source_file, output_file):
    with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        if os.path.isfile(source_file):
            zipf.write(source_file, os.path.basename(source_file))
        elif os.path.isdir(source_file):
            for root, dirs, files in os.walk(source_file):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, source_file)
                    zipf.write(file_path, arcname)

def main():
    # Crear directorios si no existen
    os.makedirs('api/lambda', exist_ok=True)
    os.makedirs('data_ingestion/layers', exist_ok=True)
    
    # Crear ZIP para authorizer
    create_zip('api/lambda/authorizer.py', 'api/lambda/authorizer.zip')
    
    # Crear ZIP para predict
    create_zip('api/lambda/predict.py', 'api/lambda/predict.zip')
    
    # Crear ZIP para kaggle_layer
    create_zip('data_ingestion/layers', 'data_ingestion/layers/kaggle_layer.zip')

if __name__ == '__main__':
    main() 