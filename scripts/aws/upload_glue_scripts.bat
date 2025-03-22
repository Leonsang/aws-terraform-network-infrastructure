@echo off
setlocal enabledelayedexpansion

:: Configuración
set PROJECT_NAME=terraform-aws
set ENVIRONMENT=dev
set SCRIPTS_BUCKET=%PROJECT_NAME%-%ENVIRONMENT%-scripts
set SCRIPTS_DIR=src\data_processing\glue

:: Verificar que el directorio de scripts existe
if not exist "%SCRIPTS_DIR%" (
    echo Error: El directorio %SCRIPTS_DIR% no existe
    exit /b 1
)

:: Crear directorio temporal para los scripts
set TEMP_DIR=%TEMP%\glue_scripts
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: Copiar scripts al directorio temporal
echo Copiando scripts...
xcopy /y "%SCRIPTS_DIR%\*.py" "%TEMP_DIR%\"

:: Subir scripts al bucket S3
echo Subiendo scripts al bucket %SCRIPTS_BUCKET%...
aws s3 cp "%TEMP_DIR%" "s3://%SCRIPTS_BUCKET%/glue/" --recursive

:: Limpiar directorio temporal
rd /s /q "%TEMP_DIR%"

echo Scripts subidos exitosamente 