@echo off
echo WELCOME TO THE FNF ZENITH CHART CONVERTER!
echo.
echo Note: The engine's chart format is built WAY different from other engines, so it might not work on
echo certain charts because it would crash the game due to a null object reference.
echo.
set /p userInput=Enter the directory of your chart - 
echo The chart's directory is: %userInput%
set /p userInputSave=Enter the directory or file name to save the converted chart at - 
echo You entered: %userInputSave%
ChartConverter %userInput% %userInputSave%