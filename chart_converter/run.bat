@echo off
echo WELCOME TO THE FNF ZENITH CHART CONVERTER!
echo.
echo Note: The engine's chart format is built WAY different from other engines, so it might not work on
echo certain charts due to throwing a null object reference at specific sections, either because the
echo note data is out of bounds, or it just isn't compatible at all
echo.
set /p userInput=Enter the directory of your chart: 
echo The chart's directory is %userInput%
set /p userInputSave=Enter the directory or file name to save the converted chart at: 
echo You entered: %userInputSave%
ChartConverter %userInput% %userInputSave%