@echo off
echo ========================================
echo Architecture Diagram Generator
echo ========================================
echo.
echo Choose your option:
echo.
echo 1. Python (Generates PNG images)
echo 2. TypeScript (Generates HTML viewer)
echo 3. Java (Generates PlantUML files)
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto python
if "%choice%"=="2" goto typescript
if "%choice%"=="3" goto java

echo Invalid choice!
pause
exit /b 1

:python
echo.
echo Installing Python dependencies...
cd python
pip install graphviz
echo.
echo Generating diagrams...
python generate_diagrams.py
echo.
echo Done! Check the output/ folder for PNG files.
pause
exit /b 0

:typescript
echo.
echo Installing TypeScript dependencies...
cd typescript
call npm install
echo.
echo Generating diagrams...
call npm run generate
echo.
echo Done! Open output/viewer.html in your browser.
start output\viewer.html
pause
exit /b 0

:java
echo.
echo Compiling Java code...
cd java
javac DiagramGenerator.java
echo.
echo Generating diagrams...
java DiagramGenerator
echo.
echo Done! Check the output/ folder for .puml files.
echo To render: java -jar plantuml.jar output/*.puml
pause
exit /b 0
