@echo off
echo ======================================
echo  BUILD WINDOWS - ACOUGUE DO LELECO
echo ======================================

echo.
echo 1) Baixando dependencias...
flutter pub get

echo.
echo 2) Analisando codigo...
flutter analyze
IF %ERRORLEVEL% NEQ 0 (
  echo.
  echo ERRO: flutter analyze falhou.
  pause
  exit /b %ERRORLEVEL%
)

echo.
echo 3) Gerando executavel Windows...
flutter build windows --release
IF %ERRORLEVEL% NEQ 0 (
  echo.
  echo ERRO: build Windows falhou.
  pause
  exit /b %ERRORLEVEL%
)

echo.
echo ======================================
echo BUILD FINALIZADO
echo Arquivos em:
echo build\windows\x64\runner\Release
echo ======================================
pause
