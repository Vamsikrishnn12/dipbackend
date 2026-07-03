# EC2 SSH Connection Test & Deploy Script

$EC2_IP = "13.235.27.182"
$EC2_USER = "ubuntu"
$PEM_FILE = "C:\DipandDashbackend\food\Dipanddash.pem"
$PROJECT_PATH = "C:\DipandDashbackend"
$RETRY_COUNT = 0
$MAX_RETRIES = 10
$WAIT_SECONDS = 15

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "EC2 SSH Connection & Deployment Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Function to test SSH
function Test-SSHConnection {
    Write-Host "Attempting SSH connection (Attempt $($RETRY_COUNT + 1)/$MAX_RETRIES)..." -ForegroundColor Yellow
    
    try {
        $result = ssh -i $PEM_FILE $EC2_USER@$EC2_IP "whoami" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SSH Connection Successful!" -ForegroundColor Green
            Write-Host "Output:" -ForegroundColor Green
            Write-Host $result -ForegroundColor Green
            return $true
        } else {
            Write-Host "Still connecting... Waiting $WAIT_SECONDS seconds..." -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "Connection attempt failed. Waiting $WAIT_SECONDS seconds..." -ForegroundColor Yellow
        return $false
    }
}

# Retry loop
while ($RETRY_COUNT -lt $MAX_RETRIES) {
    if (Test-SSHConnection) {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Green
        Write-Host "✅ Ready for Deployment!" -ForegroundColor Green
        Write-Host "======================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Open Terminal and run:" -ForegroundColor Cyan
        Write-Host "   ssh -i `"C:\DipandDashbackend\food\Dipanddash.pem`" ubuntu@13.235.27.182" -ForegroundColor Green
        Write-Host ""
        Write-Host "2. Then run deployment commands (see DEPLOYMENT_CHECKLIST.md)" -ForegroundColor Cyan
        Write-Host ""
        exit 0
    }
    
    $RETRY_COUNT++
    
    if ($RETRY_COUNT -lt $MAX_RETRIES) {
        Start-Sleep -Seconds $WAIT_SECONDS
    } else {
        break
    }
}

Write-Host ""
Write-Host "❌ Connection failed after $MAX_RETRIES attempts" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Check if instance is running:" -ForegroundColor Yellow
Write-Host "   - AWS Console -> EC2 -> Instances" -ForegroundColor Cyan
Write-Host "   - Instance should show 'running' status" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Verify Security Group rules:" -ForegroundColor Yellow
Write-Host "   - AWS Console -> Security Groups" -ForegroundColor Cyan
Write-Host "   - SSH rule should exist with port 22" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Check your internet connection:" -ForegroundColor Yellow
Write-Host "   - Run: ping google.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Wait longer and try again (rules can take 5-10 minutes to apply)" -ForegroundColor Yellow
Write-Host ""
