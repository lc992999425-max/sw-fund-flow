@echo off
chcp 936 >nul
cd /d "D:\申万行业资金流向"

:: 只用项目自带的 .venv（不依赖 WorkBuddy，也不依赖系统 Python）
set "PY=%~dp0.venv\Scripts\python.exe"
set "PYTHONIOENCODING=gbk:replace"

echo.
echo ========================================
echo   申万行业资金流向 - 数据刷新 + 同步上网
echo ========================================
echo.

if not exist "%PY%" (
    echo [错误] 没找到项目自带的运行环境 .venv
    echo.
    echo 请先双击「初始化环境.bat」建立环境（只需一次，约 2~5 分钟）。
    pause
    exit /b 1
)

:: 依赖自检：包缺失时自动补装（阿里云镜像，失败回退官方源）
"%PY%" -c "import openpyxl, tushare, pandas" >nul 2>&1
if not errorlevel 1 goto DEPS_OK

echo [提示] 检测到依赖缺失，正在自动安装（约 1~3 分钟，请勿关闭窗口）...
"%PY%" -m pip install --disable-pip-version-check -i https://mirrors.aliyun.com/pypi/simple/ -r "%~dp0requirements.txt"
"%PY%" -c "import openpyxl, tushare, pandas" >nul 2>&1
if not errorlevel 1 goto DEPS_OK

echo [提示] 镜像源安装未成功，改用官方源重试...
"%PY%" -m pip install --disable-pip-version-check -r "%~dp0requirements.txt"
"%PY%" -c "import openpyxl, tushare, pandas" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [错误] 依赖安装失败，请把上方报错信息发给助手处理。
    pause
    exit /b 1
)

:DEPS_OK

echo [1/4] 正在读取 Excel 成分表...
echo [2/4] 正在从 Tushare 拉取资金流数据（约 1~3 分钟）...
echo [3/4] 正在重新生成数据文件...
echo.

"%PY%" refresh.py

if errorlevel 1 goto FAIL

echo.
echo [4/4] 正在同步到 GitHub Pages...
copy /Y "site\fundflow_data.js" "fundflow_data.js" >nul
copy /Y "site\index.html" "index.html" >nul
copy /Y "site\echarts.min.js" "echarts.min.js" >nul
copy /Y "site\donate_wx.jpg" "donate_wx.jpg" >nul
copy /Y "site\donate_zfb.jpg" "donate_zfb.jpg" >nul
git add -A
git commit -m "auto update data" >nul 2>&1

:: 自动探测系统代理（github 在国内被墙，git 默认不走系统代理，需手动指定）
powershell -NoProfile -Command "git config --local --unset http.proxy 2>$null; git config --local --unset https.proxy 2>$null; $p=$env:HTTPS_PROXY;if(-not $p){$p=$env:HTTP_PROXY};if(-not $p){try{$s=Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings';if($s.ProxyEnable -eq 1 -and $s.ProxyServer){$p=$s.ProxyServer}}catch{}};if($p){if($p -match 'https=(https?://[^;]+)'){$p=$Matches[1]}elseif($p -match 'http=(https?://[^;]+)'){$p=$Matches[1]}elseif($p -match '^\s*(https?://)'){}elseif($p -match '^[^:]+:\d+$'){$p='http://'+$p};git config --local http.proxy $p;git config --local https.proxy $p;Write-Host ('[代理] 已为 git 设置代理: '+$p)}else{Write-Host '[代理] 未检测到代理，将直连尝试'}"

git push origin main 2>push_err.log
if errorlevel 1 (
    echo   [警告] 网上同步失败，但本地数据已更新。错误详情：
    type push_err.log
    echo   请确认 VPN/代理已开启，或把上面的错误发给助手处理。
) else (
    echo   [OK] 已同步到 GitHub，GitHub Pages 将自动更新。别人刷新浏览器即可看到最新数据。
)
del /q push_err.log >nul 2>&1

echo.
echo ========================================
echo   数据刷新完成！
echo   正在自动打开网站...
echo ========================================
start "" "site\index.html"
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('资金流数据已刷新并同步到 GitHub Pages（https://lc992999425-max.github.io/sw-fund-flow/）。别人刷新浏览器（或按 Ctrl+F5）即可看到最新数据。','刷新完成')"
goto DONE

:FAIL
echo.
echo ========================================
echo   刷新失败！错误码: %errorlevel%
echo   请把上方报错信息发给助手处理。
echo ========================================

:DONE
pause
