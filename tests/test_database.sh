#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test database installation
test_database_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SQLite installation
    echo "Testing SQLite installation..."
    local sqlite_version=$(ssh "$test_user@$test_ip" "sqlite3 --version" 2>&1)
    assert_not_empty "$sqlite_version" "SQLite should be installed"
}

# Test database backup
test_database_backup() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SQLite backup directory
    echo "Testing SQLite backup directory..."
    local sqlite_backup=$(ssh "$test_user@$test_ip" "test -d /var/backup/sqlite && echo 'exists'" 2>&1)
    assert_equals "$sqlite_backup" "exists" "SQLite backup directory should exist"
}

# Test database functionality
test_database_functionality() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SQLite basic functionality
    echo "Testing SQLite functionality..."
    local sqlite_test=$(ssh "$test_user@$test_ip" "echo 'CREATE TABLE test(id INTEGER PRIMARY KEY); DROP TABLE test;' | sqlite3 :memory:" 2>&1)
    assert_empty "$sqlite_test" "SQLite should execute basic SQL commands"
}

# Run database tests
run_database_tests() {
    echo "Running database tests..."
    
    test_database_installation
    test_database_backup
    test_database_functionality
    
    echo "Database tests completed."
}

# Execute database tests
run_database_tests
