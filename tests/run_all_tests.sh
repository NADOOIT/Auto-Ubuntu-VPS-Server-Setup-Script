#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test result counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test suite and update counters
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    
    echo -e "\n${GREEN}Running $suite_name...${NC}"
    
    # Run the test suite and capture output
    if output=$(./"$suite_script" 2>&1); then
        echo "$output"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}$output${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Create test report directory
mkdir -p test-reports

# Run all test suites
echo "Running all test suites..."

# Basic server setup tests
run_test_suite "Server Setup Tests" "test_server_setup.sh"

# Service management tests
run_test_suite "Service Management Tests" "test_service_management.sh"

# Authentication tests
run_test_suite "Authentication Tests" "test_authentication.sh"

# Network security tests
run_test_suite "Network Security Tests" "test_network_security.sh"

# SSL/TLS tests
run_test_suite "SSL/TLS Tests" "test_ssl.sh"

# Docker integration tests
run_test_suite "Docker Integration Tests" "test_docker.sh"

# NADOO-IT deployment tests
run_test_suite "NADOO-IT Deployment Tests" "test_nadoo_deployment.sh"

# Backup and recovery tests
run_test_suite "Backup and Recovery Tests" "test_backup_recovery.sh"

# Performance tests
run_test_suite "Performance Tests" "test_performance.sh"

# Backup tests
run_test_suite "Backup Tests" "test_backup.sh"

# Monitoring tests
run_test_suite "Monitoring Tests" "test_monitoring.sh"

# Mail tests
run_test_suite "Mail Tests" "test_mail.sh"

# Database tests
run_test_suite "Database Tests" "test_database.sh"

# Logging tests
run_test_suite "Logging Tests" "test_logging.sh"

# Generate summary report
echo -e "\n${GREEN}Test Summary:${NC}"
echo "Total Test Suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

# Generate HTML report
cat > test-reports/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { margin-bottom: 20px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Test Results</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Test Suites: $TOTAL_TESTS</p>
        <p class="passed">Passed: $PASSED_TESTS</p>
        <p class="failed">Failed: $FAILED_TESTS</p>
    </div>
    <div class="details">
        <h2>Test Details</h2>
        <table>
            <tr>
                <th>Test Suite</th>
                <th>Status</th>
                <th>Details</th>
            </tr>
EOF

# Add test results to HTML report
for log in test-reports/*.log; do
    suite_name=$(basename "$log" .log)
    if grep -q "FAILED" "$log"; then
        status="Failed"
        status_class="failed"
    else
        status="Passed"
        status_class="passed"
    fi
    
    # Escape log content for HTML
    details=$(cat "$log" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
    
    cat >> test-reports/index.html << EOF
            <tr>
                <td>$suite_name</td>
                <td class="$status_class">$status</td>
                <td><pre>$details</pre></td>
            </tr>
EOF
done

# Close HTML report
cat >> test-reports/index.html << EOF
        </table>
    </div>
</body>
</html>
EOF

# Exit with status based on test results
if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "\n${GREEN}All test suites passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some test suites failed. Check test-reports/index.html for details.${NC}"
    exit 1
fi
