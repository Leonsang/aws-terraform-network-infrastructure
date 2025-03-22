import os
import json
import boto3
import logging
from datetime import datetime
from botocore.exceptions import ClientError

# Configuración de logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clientes de AWS
s3 = boto3.client('s3')
codecommit = boto3.client('codecommit')
sns = boto3.client('sns')

def get_repository_files(repository_name, folder_path='/'):
    """Obtiene todos los archivos del repositorio."""
    try:
        response = codecommit.get_folder(
            repositoryName=repository_name,
            folderPath=folder_path
        )
        
        files = []
        for file in response.get('files', []):
            if file['absolutePath'].endswith('.tf') or file['absolutePath'].endswith('.md'):
                files.append(file['absolutePath'])
                
        for subFolder in response.get('subFolders', []):
            files.extend(get_repository_files(repository_name, subFolder['absolutePath']))
            
        return files
    except ClientError as e:
        logger.error(f"Error al obtener archivos del repositorio: {e}")
        raise

def get_file_content(repository_name, file_path):
    """Obtiene el contenido de un archivo del repositorio."""
    try:
        response = codecommit.get_file(
            repositoryName=repository_name,
            filePath=file_path
        )
        return response['fileContent'].decode('utf-8')
    except ClientError as e:
        logger.error(f"Error al obtener contenido del archivo {file_path}: {e}")
        raise

def generate_module_documentation(repository_name, module_path):
    """Genera documentación para un módulo específico."""
    files = get_repository_files(repository_name, module_path)
    
    module_docs = {
        'variables': [],
        'resources': [],
        'outputs': []
    }
    
    for file_path in files:
        if file_path.endswith('variables.tf'):
            content = get_file_content(repository_name, file_path)
            module_docs['variables'].extend(parse_variables(content))
        elif file_path.endswith('outputs.tf'):
            content = get_file_content(repository_name, file_path)
            module_docs['outputs'].extend(parse_outputs(content))
        elif file_path.endswith('main.tf'):
            content = get_file_content(repository_name, file_path)
            module_docs['resources'].extend(parse_resources(content))
            
    return module_docs

def parse_variables(content):
    """Parsea las variables del módulo."""
    variables = []
    # Implementar parsing de variables
    return variables

def parse_outputs(content):
    """Parsea los outputs del módulo."""
    outputs = []
    # Implementar parsing de outputs
    return outputs

def parse_resources(content):
    """Parsea los recursos del módulo."""
    resources = []
    # Implementar parsing de recursos
    return resources

def generate_html(module_docs):
    """Genera el HTML para la documentación."""
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Documentación de Infraestructura</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            h1 { color: #333; }
            h2 { color: #666; margin-top: 30px; }
            table { border-collapse: collapse; width: 100%; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f5f5f5; }
            .timestamp { color: #999; font-size: 0.9em; }
        </style>
    </head>
    <body>
        <h1>Documentación de Infraestructura</h1>
        <p class="timestamp">Última actualización: {}</p>
    """.format(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    # Agregar contenido de la documentación
    for module_name, module_data in module_docs.items():
        html += f"<h2>Módulo: {module_name}</h2>"
        
        if module_data['variables']:
            html += "<h3>Variables</h3>"
            html += "<table><tr><th>Nombre</th><th>Tipo</th><th>Descripción</th><th>Valor por defecto</th></tr>"
            for var in module_data['variables']:
                html += f"<tr><td>{var['name']}</td><td>{var['type']}</td><td>{var['description']}</td><td>{var.get('default', '-')}</td></tr>"
            html += "</table>"
            
        if module_data['resources']:
            html += "<h3>Recursos</h3>"
            html += "<table><tr><th>Tipo</th><th>Nombre</th><th>Descripción</th></tr>"
            for resource in module_data['resources']:
                html += f"<tr><td>{resource['type']}</td><td>{resource['name']}</td><td>{resource.get('description', '-')}</td></tr>"
            html += "</table>"
            
        if module_data['outputs']:
            html += "<h3>Outputs</h3>"
            html += "<table><tr><th>Nombre</th><th>Descripción</th></tr>"
            for output in module_data['outputs']:
                html += f"<tr><td>{output['name']}</td><td>{output['description']}</td></tr>"
            html += "</table>"

    html += """
    </body>
    </html>
    """
    return html

def handler(event, context):
    """Función principal del Lambda."""
    try:
        repository_name = os.environ['REPOSITORY_NAME']
        docs_bucket = os.environ['DOCS_BUCKET']
        environment = os.environ['ENVIRONMENT']
        
        # Generar documentación para cada módulo
        modules = ['monitoring', 'api', 'security', 'backup', 'costs', 'cicd']
        all_docs = {}
        
        for module in modules:
            module_path = f'infrastructure/modules/{module}'
            all_docs[module] = generate_module_documentation(repository_name, module_path)
        
        # Generar HTML
        html_content = generate_html(all_docs)
        
        # Subir a S3
        s3.put_object(
            Bucket=docs_bucket,
            Key='index.html',
            Body=html_content,
            ContentType='text/html'
        )
        
        logger.info("Documentación generada y subida exitosamente")
        return {
            'statusCode': 200,
            'body': json.dumps('Documentación actualizada exitosamente')
        }
        
    except Exception as e:
        logger.error(f"Error al generar documentación: {str(e)}")
        raise 