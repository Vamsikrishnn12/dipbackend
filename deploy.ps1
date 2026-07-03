# EC2 Deployment Script for Windows PowerShell
# This script helps you deploy to your AWS EC2 instance

param(
    [Parameter(Mandatory=$false)]
    [string]$EC2_IP = "13.235.27.182",
    
    [Parameter(Mandatory=$false)]
    [string]$EC2_USER = "ubuntu",
    
    [Parameter(Mandatory=$false)]
    [string]$PEM_FILE = "C:\DipandDashbackend\food\Dipanddash.pem"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "EC2 Deployment Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if PEM file exists
Write-Host "🔍 Checking PEM file..." -ForegroundColor Yellow
if (-not (Test-Path $PEM_FILE)) {
    Write-Host "❌ PEM file not found at: $PEM_FILE" -ForegroundColor Red
    Write-Host "Please check the file path." -ForegroundColor Red
    exit 1
}
Write-Host "✅ PEM file found: $PEM_FILE" -ForegroundColor Green
Write-Host ""

# Set PEM file permissions (Windows security)
Write-Host "🔐 Setting PEM file permissions..." -ForegroundColor Yellow
try {
    # Remove inheritance
    icacls.exe $PEM_FILE /inheritance:r /grant:r "$($env:USERNAME):(F)" | Out-Null
    Write-Host "✅ Permissions set correctly" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Warning: Could not set PEM permissions: $_" -ForegroundColor Yellow
}
Write-Host ""

# Try to connect
Write-Host "🔗 Attempting to connect to EC2..." -ForegroundColor Yellow
Write-Host "IP: $EC2_IP" -ForegroundColor Cyan
Write-Host "User: $EC2_USER" -ForegroundColor Cyan
Write-Host ""

Write-Host "Connecting... (this might take a moment)" -ForegroundColor Yellow

# Attempt SSH connection
$command = "ssh -i `"$PEM_FILE`" $EC2_USER@$EC2_IP"

try {
    # Use ssh with timeout
    & ssh -i "$PEM_FILE" "$EC2_USER@$EC2_IP" "echo '✅ Connection successful!'; whoami; pwd"
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "✅ Connected Successfully!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    
    # Offer to run deployment
    Write-Host "Ready to deploy? Run this command:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ssh -i `"$PEM_FILE`" $EC2_USER@$EC2_IP" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ Connection failed!" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1️⃣  Check if EC2 instance is RUNNING" -ForegroundColor Yellow
    Write-Host "   - Go to AWS EC2 Dashboard"
    Write-Host "   - Find 'Dipanddash' instance"
    Write-Host "   - Status should be 'running'" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "2️⃣  Check Security Group allows SSH (port 22)" -ForegroundColor Yellow
    Write-Host "   - EC2 Dashboard → Security Groups"
    Write-Host "   - Find security group for your instance"
    Write-Host "   - Add Inbound Rule:" -ForegroundColor Cyan
    Write-Host "     Type: SSH (22)" -ForegroundColor Cyan
    Write-Host "     Port: 22" -ForegroundColor Cyan
    Write-Host "     Source: YOUR_IP/32" -ForegroundColor Cyan
    Write-Host "   - Save the rule" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "3️⃣  Check your internet connection" -ForegroundColor Yellow
    Write-Host "   - Run: ping google.com" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "4️⃣  Try the manual command:" -ForegroundColor Yellow
    Write-Host "   ssh -i `"$PEM_FILE`" $EC2_USER@$EC2_IP" -ForegroundColor Cyan
    Write-Host ""
    
    exit 1
}
