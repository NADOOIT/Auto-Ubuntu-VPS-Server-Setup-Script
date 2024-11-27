#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test backup system configuration
test_backup_config() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test backup directory exists
    echo "Testing backup directory..."
    local backup_dir=$(ssh "$test_user@$test_ip" "test -d /backup && echo 'exists'" 2>&1)
    assert_equals "$backup_dir" "exists" "Backup directory should exist"
    
    # Test backup directory permissions
    echo "Testing backup directory permissions..."
    local backup_perms=$(ssh "$test_user@$test_ip" "stat -c %a /backup" 2>&1)
    assert_equals "$backup_perms" "700" "Backup directory should have secure permissions"
}

# Test backup creation
test_backup_creation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Create test file
    echo "Testing backup file creation..."
    ssh "$test_user@$test_ip" "echo 'test data' > /tmp/test_backup_file"
    
    # Test backup command
    local backup_result=$(ssh "$test_user@$test_ip" "tar -czf /backup/test_backup.tar.gz /tmp/test_backup_file 2>&1")
    assert_empty "$backup_result" "Backup creation should complete without errors"
    
    # Verify backup file exists
    local backup_exists=$(ssh "$test_user@$test_ip" "test -f /backup/test_backup.tar.gz && echo 'exists'" 2>&1)
    assert_equals "$backup_exists" "exists" "Backup file should exist"
}

# Test backup restoration
test_backup_restoration() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Remove original test file
    ssh "$test_user@$test_ip" "rm /tmp/test_backup_file"
    
    # Test restore command
    echo "Testing backup restoration..."
    local restore_result=$(ssh "$test_user@$test_ip" "cd /tmp && tar -xzf /backup/test_backup.tar.gz 2>&1")
    assert_empty "$restore_result" "Backup restoration should complete without errors"
    
    # Verify restored file content
    local restored_content=$(ssh "$test_user@$test_ip" "cat /tmp/tmp/test_backup_file" 2>&1)
    assert_equals "$restored_content" "test data" "Restored file should contain original data"
}

# Test backup rotation
test_backup_rotation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Create multiple backup files
    echo "Testing backup rotation..."
    for i in {1..3}; do
        ssh "$test_user@$test_ip" "touch /backup/backup_$i.tar.gz"
        sleep 1
    done
    
    # Keep only 2 newest backups
    local rotation_result=$(ssh "$test_user@$test_ip" "ls -t /backup/backup_*.tar.gz | tail -n +3 | xargs rm -f 2>&1")
    assert_empty "$rotation_result" "Backup rotation should complete without errors"
    
    # Verify number of remaining backups
    local backup_count=$(ssh "$test_user@$test_ip" "ls /backup/backup_*.tar.gz | wc -l" 2>&1)
    assert_equals "$backup_count" "2" "Should keep only 2 newest backups"
}

# Test backup encryption
test_backup_encryption() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Create test file for encrypted backup
    echo "Testing backup encryption..."
    ssh "$test_user@$test_ip" "echo 'secret data' > /tmp/secret_file"
    
    # Test encrypted backup creation
    local encrypt_result=$(ssh "$test_user@$test_ip" "tar -czf - /tmp/secret_file | gpg --batch --yes --passphrase 'test123' -c > /backup/encrypted_backup.tar.gz.gpg 2>&1")
    assert_empty "$encrypt_result" "Encrypted backup creation should complete without errors"
    
    # Verify encrypted backup exists
    local encrypted_exists=$(ssh "$test_user@$test_ip" "test -f /backup/encrypted_backup.tar.gz.gpg && echo 'exists'" 2>&1)
    assert_equals "$encrypted_exists" "exists" "Encrypted backup file should exist"
}

# Run backup tests
run_backup_tests() {
    start_test_suite "Backup Tests"
    
    run_test "Backup Configuration" test_backup_config
    run_test "Backup Creation" test_backup_creation
    run_test "Backup Restoration" test_backup_restoration
    run_test "Backup Rotation" test_backup_rotation
    run_test "Backup Encryption" test_backup_encryption
    
    finish_test_suite
}

# Execute backup tests
run_backup_tests
