# PowerShell script to build and run the Docker container
Write-Host "=== Building and Running Horse Detector Docker Container ===" -ForegroundColor Green

# Clean up any existing containers
Write-Host "`nCleaning up existing containers..." -ForegroundColor Yellow
docker stop horse-detector 2>$null
docker rm horse-detector 2>$null

# Build the Docker image
Write-Host "`nBuilding Docker image..." -ForegroundColor Yellow
docker build --platform linux/amd64 -t horse-detector .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Docker image built successfully!" -ForegroundColor Green
    
    # Run the container
    Write-Host "`nStarting container..." -ForegroundColor Yellow
    docker run -d --name horse-detector -p 5000:5000 horse-detector
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully!" -ForegroundColor Green
        Write-Host "`nYour Flask app is now running at: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "`nTo view logs: docker logs horse-detector" -ForegroundColor Yellow
        Write-Host "To stop: docker stop horse-detector" -ForegroundColor Yellow
        Write-Host "To remove: docker rm horse-detector" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Failed to start container" -ForegroundColor Red
        Write-Host "Check logs with: docker logs horse-detector" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
}
