# PowerShell troubleshooting script for Windows
Write-Host "=== Docker Horse Detector Troubleshooting Script ===" -ForegroundColor Green

# Check Docker installation
Write-Host "`n1. Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found or not running" -ForegroundColor Red
    exit 1
}

# Check Docker Compose
Write-Host "`n2. Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✓ Docker Compose found: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose not found" -ForegroundColor Red
    exit 1
}

# Check system architecture
Write-Host "`n3. Checking system architecture..." -ForegroundColor Yellow
$arch = $env:PROCESSOR_ARCHITECTURE
Write-Host "System Architecture: $arch" -ForegroundColor Cyan

# Check Docker Desktop status
Write-Host "`n4. Checking Docker Desktop status..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1
    if ($dockerInfo -match "ERROR") {
        Write-Host "✗ Docker Desktop is not running properly" -ForegroundColor Red
        Write-Host "Please start Docker Desktop and wait for it to be ready" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Docker Desktop is running" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Cannot connect to Docker daemon" -ForegroundColor Red
}

# Check required files
Write-Host "`n5. Checking required files..." -ForegroundColor Yellow
$requiredFiles = @("app.py", "requirements.txt", "Dockerfile", "docker-compose.yml", "gunicorn.conf.py")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $file" -ForegroundColor Red
    }
}

# Check model file
Write-Host "`n6. Checking model files..." -ForegroundColor Yellow
if (Test-Path "models/horsev2.h5") {
    $modelSize = (Get-Item "models/horsev2.h5").Length / 1MB
    Write-Host "✓ Model file found (${modelSize:N1} MB)" -ForegroundColor Green
} else {
    Write-Host "✗ Model file not found: models/horsev2.h5" -ForegroundColor Red
    Write-Host "Please ensure your model file is in the models/ directory" -ForegroundColor Yellow
}

# Clean up any existing containers/images
Write-Host "`n7. Cleaning up existing containers..." -ForegroundColor Yellow
try {
    docker stop horse-detector 2>$null
    docker rm horse-detector 2>$null
    Write-Host "✓ Cleaned up existing containers" -ForegroundColor Green
} catch {
    Write-Host "ℹ No existing containers to clean up" -ForegroundColor Cyan
}

Write-Host "`n=== Troubleshooting Solutions ===" -ForegroundColor Green
Write-Host "If you're still experiencing issues, try these solutions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Architecture Issues:" -ForegroundColor Cyan
Write-Host "   docker build --platform linux/amd64 -t horse-detector ." -ForegroundColor White
Write-Host ""
Write-Host "2. Clear Docker cache:" -ForegroundColor Cyan
Write-Host "   docker system prune -a" -ForegroundColor White
Write-Host ""
Write-Host "3. Use alternative Dockerfile:" -ForegroundColor Cyan
Write-Host "   docker build -f Dockerfile-alternative -t horse-detector ." -ForegroundColor White
Write-Host ""
Write-Host "4. Build without cache:" -ForegroundColor Cyan
Write-Host "   docker build --no-cache -t horse-detector ." -ForegroundColor White
Write-Host ""
Write-Host "5. Enable BuildKit:" -ForegroundColor Cyan
Write-Host "   Set-Variable -Name DOCKER_BUILDKIT -Value 1" -ForegroundColor White
Write-Host "   docker build -t horse-detector ." -ForegroundColor White

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "Try building with explicit platform:" -ForegroundColor Yellow
Write-Host "docker build --platform linux/amd64 -t horse-detector ." -ForegroundColor White