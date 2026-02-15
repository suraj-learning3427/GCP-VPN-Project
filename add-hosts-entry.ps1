# Add Jenkins to hosts file
# Run this script as Administrator

Write-Host "Adding Jenkins to hosts file..." -ForegroundColor Yellow
Write-Host ""

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "10.10.10.100 jenkins.np.learningmyway.space"

# Check if entry already exists
$hostsContent = Get-Content $hostsPath
if ($hostsContent -match "jenkins.np.learningmyway.space") {
    Write-Host "Entry already exists in hosts file!" -ForegroundColor Green
    Write-Host ""
    Get-Content $hostsPath | Select-String "jenkins"
}
else {
    try {
        Add-Content -Path $hostsPath -Value "`n$entry"
        Write-Host "SUCCESS! Hosts file entry added." -ForegroundColor Green
        Write-Host ""
        Write-Host "Entry added:" -ForegroundColor Cyan
        Write-Host "  $entry"
        Write-Host ""
        Write-Host "Verify:" -ForegroundColor Yellow
        Get-Content $hostsPath | Select-String "jenkins"
    }
    catch {
        Write-Host "ERROR: Failed to add hosts entry" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure you are running PowerShell as Administrator!" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Next step: Connect to VPN and access Jenkins" -ForegroundColor Yellow
Write-Host "URL: https://jenkins.np.learningmyway.space" -ForegroundColor White
