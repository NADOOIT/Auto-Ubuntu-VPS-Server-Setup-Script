#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test full server setup flow
test_full_server_setup() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test complete server setup
    echo "Testing complete server setup..."
    local setup_result=$(setup_server_fresh "$test_ip" "$test_user" 2>&1)
    assert_contains "$setup_result" "setup complete" "Server setup should complete successfully"
    
    # Test service deployment
    echo "Testing service deployment..."
    local deploy_result=$(install_docker_portainer "$test_ip" "$test_user" 2>&1)
    assert_contains "$deploy_result" "installation complete" "Docker and Portainer should install successfully"
    
    # Test NADOO-IT deployment
    echo "Testing NADOO-IT deployment..."
    local nadoo_result=$(install_nadoo_it "$test_ip" "$test_user" 2>&1)
    assert_contains "$nadoo_result" "installation complete" "NADOO-IT should install successfully"
    
    # Test SSL setup
    echo "Testing SSL setup..."
    local ssl_result=$(setup_ssl "$test_ip" "$test_user" 2>&1)
    assert_contains "$ssl_result" "SSL setup complete" "SSL should setup successfully"
}

# Test error handling
test_error_handling() {
    local invalid_ip="999.999.999.999"
    local invalid_user="nonexistent"
    
    # Test invalid SSH connection
    echo "Testing invalid SSH connection..."
    local ssh_result=$(verify_ssh_connection "$invalid_ip" "$invalid_user" 2>&1)
    assert_contains "$ssh_result" "failed" "Invalid SSH connection should fail gracefully"
    
    # Test invalid SSL setup
    echo "Testing invalid SSL setup..."
    local ssl_result=$(setup_ssl "$invalid_ip" "$invalid_user" 2>&1)
    assert_contains "$ssl_result" "failed" "Invalid SSL setup should fail gracefully"
}

# Test configuration management
test_config_management() {
    # Test config initialization
    echo "Testing config initialization..."
    local init_result=$(initialize_config 2>&1)
    assert_contains "$init_result" "initialized" "Config should initialize successfully"
    
    # Test server addition
    echo "Testing server addition..."
    local add_result=$(add_server "test.server.com" "test_user" 2>&1)
    assert_contains "$add_result" "added" "Server should be added successfully"
    
    # Test server removal
    echo "Testing server removal..."
    local remove_result=$(remove_server "test.server.com" 2>&1)
    assert_contains "$remove_result" "removed" "Server should be removed successfully"
}

# Run integration tests
run_integration_tests() {
    start_test_suite "Integration Tests"
    
    run_test "Full Server Setup" test_full_server_setup
    run_test "Error Handling" test_error_handling
    run_test "Configuration Management" test_config_management
    
    finish_test_suite
}

# Execute integration tests
run_integration_tests
