@echo off
setlocal enabledelayedexpansion

:: Configuración
set PROJECT_NAME=terraform-aws
set ENVIRONMENT=dev
set AWS_REGION=us-east-1
set S3_BUCKET=%PROJECT_NAME%-%ENVIRONMENT%-scripts
set GLUE_JOB=%PROJECT_NAME%-%ENVIRONMENT%-raw-processing
set RAW_BUCKET=%PROJECT_NAME%-%ENVIRONMENT%-storage-314146337854
set PROCESSED_BUCKET=%PROJECT_NAME%-%ENVIRONMENT%-processed
set LOG_GROUP=/aws-glue/jobs/%GLUE_JOB%
set MAX_RETRIES=3
set RETRY_DELAY=30

:: Colores para la salida
set RED=\033[0;31m
set GREEN=\033[0;32m
set YELLOW=\033[1;33m
set NC=\033[0m

:: Función para mostrar mensajes
:show_message
echo %~1
exit /b 0

:: Función para verificar errores
:check_error
if errorlevel 1 (
    echo %RED%Error: %~1%NC%
    exit /b 1
)
exit /b 0

:: Función para esperar
:wait
timeout /t %~1 /nobreak >nul
exit /b 0

:: Función para verificar estado del job
:check_job_status
set JOB_STATUS=
for /f "tokens=*" %%a in ('aws glue get-job-run --job-name %GLUE_JOB% --run-id %JOB_RUN_ID% --region %AWS_REGION% --query "JobRun.JobRunState" --output text') do set JOB_STATUS=%%a
if "%JOB_STATUS%"=="SUCCEEDED" (
    echo %GREEN%Job completado exitosamente%NC%
    exit /b 0
) else if "%JOB_STATUS%"=="FAILED" (
    echo %RED%Job falló%NC%
    exit /b 1
) else if "%JOB_STATUS%"=="RUNNING" (
    echo %YELLOW%Job en ejecución...%NC%
    exit /b 2
) else (
    echo %RED%Estado desconocido: %JOB_STATUS%%NC%
    exit /b 1
)

:: Función para obtener logs
:get_logs
echo %YELLOW%Obteniendo logs...%NC%
aws logs get-log-events --log-group-name %LOG_GROUP% --log-stream-name %JOB_RUN_ID% --region %AWS_REGION% --limit 100
exit /b 0

:: Función para retry
:retry
set /a RETRY_COUNT+=1
if %RETRY_COUNT% leq %MAX_RETRIES% (
    echo %YELLOW%Reintentando... (%RETRY_COUNT%/%MAX_RETRIES%)%NC%
    call :wait %RETRY_DELAY%
    goto %~1
) else (
    echo %RED%Máximo número de reintentos alcanzado%NC%
    exit /b 1
)

:: Inicio del script
echo %GREEN%====================================
echo Iniciando proceso ETL
echo ====================================%NC%

:: Verificar AWS CLI
aws --version >nul 2>&1
call :check_error "AWS CLI no está instalado"

:: Verificar credenciales
aws sts get-caller-identity >nul 2>&1
call :check_error "Credenciales de AWS no configuradas"

:: Verificar que el bucket existe
echo %YELLOW%Verificando bucket S3...%NC%
aws s3api head-bucket --bucket %S3_BUCKET% 2>nul
call :check_error "El bucket %S3_BUCKET% no existe"

:: Subir scripts a S3
echo %YELLOW%Subiendo scripts...%NC%
aws s3 cp src/data_processing/glue/raw_processing.py s3://%S3_BUCKET%/glue/
call :check_error "No se pudo subir raw_processing.py"

:: Iniciar Glue Job
echo %YELLOW%Iniciando Glue Job...%NC%
for /f "tokens=*" %%a in ('aws glue start-job-run --job-name %GLUE_JOB% --region %AWS_REGION% --arguments "{\"--input_path\":\"s3://%RAW_BUCKET%/raw/creditcardfraud/creditcard.csv\",\"--output_path\":\"s3://%PROCESSED_BUCKET%/processed/transactions/\"}" --query "JobRunId" --output text') do set JOB_RUN_ID=%%a

echo %GREEN%Job Run ID: %JOB_RUN_ID%%NC%

:: Monitorear estado del job
:monitor_job
call :check_job_status
if errorlevel 2 (
    call :get_logs
    call :wait 30
    goto monitor_job
)

:: Verificar resultado final
if errorlevel 1 (
    echo %RED%El job falló. Revisando logs...%NC%
    call :get_logs
    exit /b 1
) else (
    echo %GREEN%Proceso ETL completado exitosamente%NC%
    echo %YELLOW%Para ver los logs completos, ejecuta:%NC%
    echo aws logs get-log-events --log-group-name %LOG_GROUP% --log-stream-name %JOB_RUN_ID% --region %AWS_REGION%
)

exit /b 0 