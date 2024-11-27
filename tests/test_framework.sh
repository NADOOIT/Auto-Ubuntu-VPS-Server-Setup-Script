#!/bin/bash

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Start a test suite
start_test_suite() {
    local suite_name="$1"
    echo -e "\n${YELLOW}Starting Test Suite: ${suite_name}${NC}"
    echo "═══════════════════════════════════════"
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
}

# Run a single test
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "\n${YELLOW}Running Test: ${test_name}${NC}"
    if $test_function; then
        echo -e "${GREEN}✓ Test passed${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ Test failed${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Finish test suite and display results
finish_test_suite() {
    echo -e "\n${YELLOW}Test Results${NC}"
    echo "═══════════════════════════════════════"
    echo -e "Total Tests: ${TOTAL_TESTS}"
    echo -e "Passed: ${GREEN}${PASSED_TESTS}${NC}"
    echo -e "Failed: ${RED}${FAILED_TESTS}${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Assert functions
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="$3"
    
    if [ "$actual" = "$expected" ]; then
        return 0
    else
        echo -e "${RED}Assertion failed: ${message}${NC}"
        echo "Expected: $expected"
        echo "Actual: $actual"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="$2"
    
    if [ -n "$value" ]; then
        return 0
    else
        echo -e "${RED}Assertion failed: ${message}${NC}"
        echo "Value is empty"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    
    if echo "$haystack" | grep -q "$needle"; then
        return 0
    else
        echo -e "${RED}Assertion failed: ${message}${NC}"
        echo "Expected to find: $needle"
        echo "In: $haystack"
        return 1
    fi
}

assert_length_greater_than() {
    local value="$1"
    local min_length="$2"
    local message="$3"
    
    if [ ${#value} -gt $min_length ]; then
        return 0
    else
        echo -e "${RED}Assertion failed: ${message}${NC}"
        echo "Expected length > $min_length"
        echo "Actual length: ${#value}"
        return 1
    fi
}
