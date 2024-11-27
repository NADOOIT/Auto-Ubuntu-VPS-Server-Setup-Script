#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test service installation
test_service_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test essential services
    echo "Testing essential services installation..."
    local services=(
        "nginx"
        "docker"
        "mysql"
        "redis-server"
        "mongodb"
        "postfix"
        "dovecot"
        "spamassassin"
        "fail2ban"
        "ufw"
        "rsyslog"
        "auditd"
    )
    
    for service in "${services[@]}"; do
        local service_status=$(ssh "$test_user@$test_ip" "systemctl is-active $service" 2>&1)
        assert_equals "$service_status" "active" "$service should be running"
    done
}

# Test service configuration
test_service_configuration() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Nginx configuration
    echo "Testing Nginx configuration..."
    local nginx_conf=$(ssh "$test_user@$test_ip" "nginx -t 2>&1")
    assert_contains "$nginx_conf" "successful" "Nginx config should be valid"
    
    # Test MySQL configuration
    echo "Testing MySQL configuration..."
    local mysql_conf=$(ssh "$test_user@$test_ip" "mysqld --help --verbose 2>&1")
    assert_contains "$mysql_conf" "Version" "MySQL config should be valid"
    
    # Test Redis configuration
    echo "Testing Redis configuration..."
    local redis_conf=$(ssh "$test_user@$test_ip" "redis-cli ping" 2>&1)
    assert_equals "$redis_conf" "PONG" "Redis should respond to ping"
}

# Test service dependencies
test_service_dependencies() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test service order
    echo "Testing service dependencies..."
    local service_order=$(ssh "$test_user@$test_ip" "systemctl list-dependencies" 2>&1)
    assert_contains "$service_order" "network.target" "Network should be a dependency"
    
    # Test required services
    echo "Testing required services..."
    local required_services=$(ssh "$test_user@$test_ip" "systemctl list-dependencies --reverse" 2>&1)
    assert_not_empty "$required_services" "Should have dependent services"
}

# Test service logging
test_service_logging() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Nginx logs
    echo "Testing Nginx logs..."
    local nginx_logs=$(ssh "$test_user@$test_ip" "test -f /var/log/nginx/access.log && echo 'exists'" 2>&1)
    assert_equals "$nginx_logs" "exists" "Nginx logs should exist"
    
    # Test MySQL logs
    echo "Testing MySQL logs..."
    local mysql_logs=$(ssh "$test_user@$test_ip" "test -f /var/log/mysql/error.log && echo 'exists'" 2>&1)
    assert_equals "$mysql_logs" "exists" "MySQL logs should exist"
    
    # Test mail logs
    echo "Testing mail logs..."
    local mail_logs=$(ssh "$test_user@$test_ip" "test -f /var/log/mail.log && echo 'exists'" 2>&1)
    assert_equals "$mail_logs" "exists" "Mail logs should exist"
}

# Test service recovery
test_service_recovery() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test service restart
    echo "Testing service restart..."
    local restart_result=$(ssh "$test_user@$test_ip" "systemctl restart nginx" 2>&1)
    assert_empty "$restart_result" "Service restart should succeed"
    
    # Test service reload
    echo "Testing service reload..."
    local reload_result=$(ssh "$test_user@$test_ip" "systemctl reload nginx" 2>&1)
    assert_empty "$reload_result" "Service reload should succeed"
    
    # Test failure recovery
    echo "Testing failure recovery..."
    local recovery_config=$(ssh "$test_user@$test_ip" "systemctl show nginx -p Restart" 2>&1)
    assert_contains "$recovery_config" "always" "Service should auto-restart"
}

# Test service security
test_service_security() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test service users
    echo "Testing service users..."
    local service_users=$(ssh "$test_user@$test_ip" "ps aux | grep nginx | grep -v root | head -1" 2>&1)
    assert_contains "$service_users" "www-data" "Services should run as non-root"
    
    # Test service permissions
    echo "Testing service permissions..."
    local service_perms=$(ssh "$test_user@$test_ip" "ls -l /etc/nginx/nginx.conf" 2>&1)
    assert_contains "$service_perms" "644" "Config files should have correct permissions"
    
    # Test service isolation
    echo "Testing service isolation..."
    local isolation_config=$(ssh "$test_user@$test_ip" "systemctl show nginx -p PrivateTmp" 2>&1)
    assert_contains "$isolation_config" "yes" "Services should be isolated"
}

# Run service tests
run_service_tests() {
    start_test_suite "Service Tests"
    
    run_test "Service Installation" test_service_installation
    run_test "Service Configuration" test_service_configuration
    run_test "Service Dependencies" test_service_dependencies
    run_test "Service Logging" test_service_logging
    run_test "Service Recovery" test_service_recovery
    run_test "Service Security" test_service_security
    
    finish_test_suite
}

# Execute service tests
run_service_tests
