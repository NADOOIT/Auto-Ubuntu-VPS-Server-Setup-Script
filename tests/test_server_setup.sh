#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test server setup functions
test_server_setup() {
    # Setup
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test generate_secure_password
    local password=$(generate_secure_password)
    assert_not_empty "$password" "Password generation should not return empty"
    assert_length_greater_than "$password" 12 "Password should be at least 12 characters"
    
    # Test SSH connection
    local ssh_result=$(verify_ssh_connection "$test_ip" "$test_user" 2>&1)
    assert_contains "$ssh_result" "Connection attempt" "SSH verification should attempt connection"
    
    # Test Docker installation check
    local docker_check=$(check_docker_installation "$test_ip" "$test_user" 2>&1)
    assert_contains "$docker_check" "docker" "Docker check should contain docker keyword"
}

# Test SSL certificate management
test_ssl_management() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test SSL setup
    local ssl_result=$(setup_ssl "$test_ip" "$test_user" 2>&1)
    assert_contains "$ssl_result" "certificate" "SSL setup should mention certificates"
    
    # Test certificate renewal
    local renewal_result=$(check_ssl_renewal "$test_ip" "$test_user" 2>&1)
    assert_contains "$renewal_result" "renew" "SSL renewal check should contain renew keyword"
}

# Test authentication methods
test_authentication() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test FIDO2 setup
    local fido2_result=$(setup_fido2 "$test_ip" "$test_user" 2>&1)
    assert_contains "$fido2_result" "security key" "FIDO2 setup should mention security key"
    
    # Test password authentication toggle
    local auth_result=$(toggle_password_auth "$test_ip" "$test_user" 2>&1)
    assert_contains "$auth_result" "authentication" "Password auth toggle should mention authentication"
}

# Run all tests
run_test_suite() {
    start_test_suite "Server Management Tests"
    
    run_test "Server Setup Tests" test_server_setup
    run_test "SSL Management Tests" test_ssl_management
    run_test "Authentication Tests" test_authentication
    
    finish_test_suite
}

# Execute tests
run_test_suite
