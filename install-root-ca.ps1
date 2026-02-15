# Install Root CA Certificate
# Run this script as Administrator

Write-Host "Installing LearningMyWay Root CA Certificate..." -ForegroundColor Yellow
Write-Host ""

$certPath = "C:\Testing\LearningMyWay-Root-CA.crt"

if (-not (Test-Path $certPath)) {
    Write-Host "ERROR: Certificate file not found at: $certPath" -ForegroundColor Red
    Write-Host "Please make sure the file exists in C:\Testing\" -ForegroundColor Red
    exit 1
}

try {
    $cert = Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root
    Write-Host "SUCCESS! Root CA certificate installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Certificate Details:" -ForegroundColor Cyan
    Write-Host "  Subject: $($cert.Subject)"
    Write-Host "  Thumbprint: $($cert.Thumbprint)"
    Write-Host "  Valid Until: $($cert.NotAfter)"
    Write-Host ""
    Write-Host "Next step: Add hosts file entry" -ForegroundColor Yellow
    Write-Host "Run: Add-Content C:\Windows\System32\drivers\etc\hosts `"`n10.10.10.100 jenkins.np.learningmyway.space`"" -ForegroundColor White
}
catch {
    Write-Host "ERROR: Failed to install certificate" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you are running PowerShell as Administrator!" -ForegroundColor Yellow
    exit 1
}
