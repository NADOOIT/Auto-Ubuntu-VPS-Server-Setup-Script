#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test Docker and Portainer management
test_docker_management() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test Docker installation
    echo "Testing Docker installation..."
    local docker_result=$(install_docker_portainer "$test_ip" "$test_user" 2>&1)
    assert_contains "$docker_result" "Docker installation complete" "Docker should install successfully"
    
    # Test Docker service status
    echo "Testing Docker service..."
    local status_result=$(check_service_status "$test_ip" "$test_user" "docker" 2>&1)
    assert_contains "$status_result" "active" "Docker service should be active"
    
    # Test Portainer deployment
    echo "Testing Portainer deployment..."
    local portainer_result=$(check_service_status "$test_ip" "$test_user" "portainer" 2>&1)
    assert_contains "$portainer_result" "running" "Portainer container should be running"
}

# Test NADOO-IT deployment
test_nadoo_deployment() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test NADOO-IT installation
    echo "Testing NADOO-IT installation..."
    local install_result=$(install_nadoo_it "$test_ip" "$test_user" 2>&1)
    assert_contains "$install_result" "installation complete" "NADOO-IT should install successfully"
    
    # Test environment setup
    echo "Testing environment configuration..."
    local env_result=$(ssh "$test_user@$test_ip" "test -f ~/NADOO-IT/.env && echo 'exists'" 2>&1)
    assert_contains "$env_result" "exists" "Environment file should exist"
    
    # Test container status
    echo "Testing container status..."
    local container_result=$(check_service_status "$test_ip" "$test_user" "nadoo-it" 2>&1)
    assert_contains "$container_result" "running" "NADOO-IT containers should be running"
}

# Test service monitoring
test_service_monitoring() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test service status check
    echo "Testing service status check..."
    local status_result=$(check_service_status "$test_ip" "$test_user" 2>&1)
    assert_contains "$status_result" "Status" "Service status should be displayed"
    
    # Test Docker logs
    echo "Testing Docker logs..."
    local logs_result=$(check_docker_logs "$test_ip" "$test_user" "portainer" 2>&1)
    assert_not_empty "$logs_result" "Docker logs should not be empty"
    
    # Test SSL certificate status
    echo "Testing SSL certificate status..."
    local ssl_result=$(check_ssl_status "$test_ip" "$test_user" 2>&1)
    assert_contains "$ssl_result" "certificate" "SSL certificate status should be available"
}

# Test error recovery
test_error_recovery() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test Docker service recovery
    echo "Testing Docker service recovery..."
    local recovery_result=$(recover_docker_service "$test_ip" "$test_user" 2>&1)
    assert_contains "$recovery_result" "recovered" "Docker service should recover successfully"
    
    # Test container restart
    echo "Testing container restart..."
    local restart_result=$(restart_container "$test_ip" "$test_user" "portainer" 2>&1)
    assert_contains "$restart_result" "restarted" "Container should restart successfully"
    
    # Test service cleanup
    echo "Testing service cleanup..."
    local cleanup_result=$(cleanup_services "$test_ip" "$test_user" 2>&1)
    assert_contains "$cleanup_result" "cleaned" "Services should clean up successfully"
}

# Run service management tests
run_service_tests() {
    start_test_suite "Service Management Tests"
    
    run_test "Docker Management" test_docker_management
    run_test "NADOO-IT Deployment" test_nadoo_deployment
    run_test "Service Monitoring" test_service_monitoring
    run_test "Error Recovery" test_error_recovery
    
    finish_test_suite
}

# Execute service tests
run_service_tests
