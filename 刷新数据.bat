@echo off
chcp 65001 >nul
cd /d "D:\申万行业资金流向"

set "PY=C:\Users\Administrator\.workbuddy\binaries\python\envs\default\Scripts\python.exe"

echo.
echo ========================================
echo   申万行业资金流向 - 数据刷新 + 同步上网
echo ========================================
echo.

if not exist "%PY%" (
    echo [错误] 找不到 Python 环境：
    echo   %PY%
    echo.
    echo 请在 WorkBuddy 对话框里发送"刷新数据"，让助手帮你刷新。
    pause
    exit /b 1
)

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
