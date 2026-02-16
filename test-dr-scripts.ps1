# DR Scripts Test Suite
Write-Host "========================================" -ForegroundColor Blue
Write-Host "DR Scripts Test Suite" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

$TestsPassed = 0
$TestsFailed = 0

# Test 1
Write-Host "Test 1: Backup script exists" -ForegroundColor Yellow
if (Test-Path "scripts/backup-jenkins.sh") {
    Write-Host "PASS - backup-jenkins.sh found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - backup-jenkins.sh not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Test 2
Write-Host "Test 2: Restore script exists" -ForegroundColor Yellow
if (Test-Path "scripts/restore-jenkins.sh") {
    Write-Host "PASS - restore-jenkins.sh found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - restore-jenkins.sh not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Test 3
Write-Host "Test 3: DR Runbook exists" -ForegroundColor Yellow
if (Test-Path "DISASTER-RECOVERY-RUNBOOK.md") {
    Write-Host "PASS - DISASTER-RECOVERY-RUNBOOK.md found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - DISASTER-RECOVERY-RUNBOOK.md not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Test 4
Write-Host "Test 4: RTO/RPO Analysis exists" -ForegroundColor Yellow
if (Test-Path "RTO-RPO-ANALYSIS.md") {
    Write-Host "PASS - RTO-RPO-ANALYSIS.md found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - RTO-RPO-ANALYSIS.md not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Test 5
Write-Host "Test 5: Lab Report exists" -ForegroundColor Yellow
if (Test-Path "LAB4-DR-SIMULATION-REPORT.md") {
    Write-Host "PASS - LAB4-DR-SIMULATION-REPORT.md found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - LAB4-DR-SIMULATION-REPORT.md not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Test 6
Write-Host "Test 6: Quick Start Guide exists" -ForegroundColor Yellow
if (Test-Path "LAB4-QUICK-START.md") {
    Write-Host "PASS - LAB4-QUICK-START.md found" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "FAIL - LAB4-QUICK-START.md not found" -ForegroundColor Red
    $TestsFailed++
}
Write-Host ""

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "Test Results Summary" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Tests Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $TestsFailed" -ForegroundColor Red
Write-Host "Total Tests: $($TestsPassed + $TestsFailed)"
Write-Host ""

if ($TestsFailed -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "Lab 4: Disaster Recovery is ready!" -ForegroundColor Green
} else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "Please review the failed tests above." -ForegroundColor Yellow
}
