@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ==========================================
echo   正在启动 Guncat AI 本地服务
echo   访问地址：http://localhost:8080
echo ==========================================
echo.
echo 提示：关闭本窗口即可停止服务
echo.

start http://localhost:8080
python -m http.server 8080
