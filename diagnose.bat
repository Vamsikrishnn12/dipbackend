@echo off
REM EC2 SSH Diagnostic Script

echo ======================================
echo EC2 SSH Connection Diagnostic
echo ======================================
echo.

echo Checking network connectivity...
echo.

REM Check if we can reach the IP
echo 1. Testing basic connectivity to 13.235.27.182...
ping -n 1 13.235.27.182

if errorlevel 1 (
    echo - Ping failed. IP might not be reachable.
) else (
    echo - Ping successful!
)

echo.
echo 2. Testing port 22 availability...
timeout /t 2 /nobreak

REM Try SSH with verbose output
echo.
echo 3. Attempting SSH connection...
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182 -v

echo.
echo If SSH still doesn't work:
echo - Check AWS Security Group allows SSH from your IP
echo - Check instance is still running
echo - Try rebooting the instance
echo.
pause
