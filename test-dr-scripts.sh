#!/bin/bash
################################################################################
# DR Scripts Test Suite
# Purpose: Validate backup and restore scripts without actual Jenkins
# Usage: bash test-dr-scripts.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DR Scripts Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check if backup script exists
echo -e "${YELLOW}Test 1: Backup script exists${NC}"
if [ -f "scripts/backup-jenkins.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC} - backup-jenkins.sh found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - backup-jenkins.sh not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 2: Check if restore script exists
echo -e "${YELLOW}Test 2: Restore script exists${NC}"
if [ -f "scripts/restore-jenkins.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC} - restore-jenkins.sh found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - restore-jenkins.sh not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 3: Check backup script syntax
echo -e "${YELLOW}Test 3: Backup script syntax${NC}"
if bash -n scripts/backup-jenkins.sh 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} - No syntax errors in backup-jenkins.sh"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Syntax errors in backup-jenkins.sh"
    ((TESTS_FAILED++))
fi
echo ""

# Test 4: Check restore script syntax
echo -e "${YELLOW}Test 4: Restore script syntax${NC}"
if bash -n scripts/restore-jenkins.sh 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} - No syntax errors in restore-jenkins.sh"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Syntax errors in restore-jenkins.sh"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: Check backup script has required functions
echo -e "${YELLOW}Test 5: Backup script completeness${NC}"
REQUIRED_ITEMS=("JENKINS_HOME" "BACKUP_DIR" "tar -czf" "mkdir -p")
MISSING=0
for item in "${REQUIRED_ITEMS[@]}"; do
    if ! grep -q "$item" scripts/backup-jenkins.sh; then
        echo -e "${RED}  Missing: $item${NC}"
        ((MISSING++))
    fi
done
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - All required components present"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Missing $MISSING required components"
    ((TESTS_FAILED++))
fi
echo ""

# Test 6: Check restore script has required functions
echo -e "${YELLOW}Test 6: Restore script completeness${NC}"
REQUIRED_ITEMS=("JENKINS_HOME" "tar -xzf" "systemctl stop jenkins" "systemctl start jenkins")
MISSING=0
for item in "${REQUIRED_ITEMS[@]}"; do
    if ! grep -q "$item" scripts/restore-jenkins.sh; then
        echo -e "${RED}  Missing: $item${NC}"
        ((MISSING++))
    fi
done
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - All required components present"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Missing $MISSING required components"
    ((TESTS_FAILED++))
fi
echo ""

# Test 7: Check DR runbook exists
echo -e "${YELLOW}Test 7: DR Runbook exists${NC}"
if [ -f "DISASTER-RECOVERY-RUNBOOK.md" ]; then
    echo -e "${GREEN}✓ PASS${NC} - DISASTER-RECOVERY-RUNBOOK.md found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - DISASTER-RECOVERY-RUNBOOK.md not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 8: Check RTO/RPO analysis exists
echo -e "${YELLOW}Test 8: RTO/RPO Analysis exists${NC}"
if [ -f "RTO-RPO-ANALYSIS.md" ]; then
    echo -e "${GREEN}✓ PASS${NC} - RTO-RPO-ANALYSIS.md found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - RTO-RPO-ANALYSIS.md not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 9: Check lab report exists
echo -e "${YELLOW}Test 9: Lab Report exists${NC}"
if [ -f "LAB4-DR-SIMULATION-REPORT.md" ]; then
    echo -e "${GREEN}✓ PASS${NC} - LAB4-DR-SIMULATION-REPORT.md found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - LAB4-DR-SIMULATION-REPORT.md not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 10: Check runbook has all scenarios
echo -e "${YELLOW}Test 10: DR Runbook completeness${NC}"
SCENARIOS=("Jenkins VM" "VPN Gateway" "Complete Infrastructure" "Certificate")
MISSING=0
for scenario in "${SCENARIOS[@]}"; do
    if ! grep -q "$scenario" DISASTER-RECOVERY-RUNBOOK.md; then
        echo -e "${RED}  Missing scenario: $scenario${NC}"
        ((MISSING++))
    fi
done
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - All 4 scenarios documented"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Missing $MISSING scenarios"
    ((TESTS_FAILED++))
fi
echo ""

# Test 11: Check RTO/RPO values are documented
echo -e "${YELLOW}Test 11: RTO/RPO values documented${NC}"
if grep -q "RTO" RTO-RPO-ANALYSIS.md && grep -q "RPO" RTO-RPO-ANALYSIS.md; then
    echo -e "${GREEN}✓ PASS${NC} - RTO and RPO values documented"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - RTO/RPO values not found"
    ((TESTS_FAILED++))
fi
echo ""

# Test 12: Check Terraform configuration exists
echo -e "${YELLOW}Test 12: Terraform configuration${NC}"
if [ -f "terraform/main.tf" ] && [ -f "terraform/variables.tf" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Terraform configuration found"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Terraform configuration incomplete"
    ((TESTS_FAILED++))
fi
echo ""

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Lab 4: Disaster Recovery is ready for deployment!"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Please review the failed tests above."
    exit 1
fi
