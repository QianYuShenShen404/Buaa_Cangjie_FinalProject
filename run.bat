@echo off
setlocal

:: 获取当前脚本所在目录
set "current_dir=%cd%"

:: 设置 main.exe 路径
set "main_exe_path=%current_dir%\target\release\bin\main.exe"

:: 使用 wscript 启动 main.exe 并隐藏窗口
echo Running %main_exe_path%...
start /min "" "%main_exe_path%"

:: 或者使用 vbscript 静默启动
:: echo Running %main_exe_path%...
:: echo Set WshShell = CreateObject("WScript.Shell"^) > hide.vbs
:: echo WshShell.Run Chr(34^) ^& "%main_exe_path%" ^& Chr(34^), 0, False >> hide.vbs
:: start /wait wscript //B hide.vbs

:: 等待 3 秒，确保程序已启动（可调整）
timeout /t 3 >nul

:: 打开网页文件
echo Opening index.html in default browser...
start "" "%current_dir%\src\website\index.html"

:: 防止窗口一闪而过
pause