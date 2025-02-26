@echo off
setlocal enabledelayedexpansion

:: Check if Docker is installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Docker is not installed. Please install Docker and try again.
    pause
    exit /b
)

:: Check if Docker daemon is running
docker info >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Docker is not running. Please start Docker and try again.
    pause
    exit /b
)

:: Ask for Docker image name
set /p IMAGE_NAME=Enter Docker image name: 
set IMAGE_NAME=%IMAGE_NAME: =%

:: Validate image name (non-empty)
if "%IMAGE_NAME%"=="" (
    echo Error: Docker image name cannot be empty.
    pause
    exit /b
)

:: Check if port 8888 is available; if not, find next available port
set PORT=8888
:CHECK_PORT
netstat -ano | findstr ":%PORT%" >nul
if %errorlevel% equ 0 (
    set /a PORT+=1
    goto CHECK_PORT
)

echo Using port %PORT%...

:: Generate a unique container name
set CONTAINER_NAME=%IMAGE_NAME%_container_%random%

echo Creating and starting container: %CONTAINER_NAME%...

:: Run the container
docker run --gpus all -p %PORT%:8888 -it -d --name %CONTAINER_NAME% %IMAGE_NAME%
if %errorlevel% neq 0 (
    echo Error: Failed to start the container.
    pause
    exit /b
)

:: Wait for a few seconds to ensure the container starts
timeout /t 10 >nul

:: Check if container is running
docker ps --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /C:"%CONTAINER_NAME%" >nul
if %errorlevel% neq 0 (
    echo Error: Container failed to start.
    pause
    exit /b
)

echo Running Jupyter Lab inside the container...

:: Run Jupyter Lab inside the container
start cmd /k docker exec -it %CONTAINER_NAME% bash -c "jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token="

:: Wait a few seconds to allow Jupyter to start
timeout /t 5s >nul

:: Open Jupyter Lab in browser
echo Opening Jupyter Lab in the browser...
start "" "http://127.0.0.1:%PORT%/lab"

:: Open another terminal and attach it to the running container
start cmd /k docker exec -it %CONTAINER_NAME% bash

echo Done! Press [Enter] to exit...
pause
