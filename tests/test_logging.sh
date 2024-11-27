#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test logging system installation
test_logging_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test rsyslog installation
    echo "Testing rsyslog installation..."
    local rsyslog_status=$(ssh "$test_user@$test_ip" "systemctl is-active rsyslog" 2>&1)
    assert_equals "$rsyslog_status" "active" "Rsyslog should be running"
    
    # Test logrotate installation
    echo "Testing logrotate installation..."
    local logrotate_exists=$(ssh "$test_user@$test_ip" "test -f /etc/logrotate.conf && echo 'exists'" 2>&1)
    assert_equals "$logrotate_exists" "exists" "Logrotate should be installed"
    
    # Test ELK stack installation (if configured)
    echo "Testing ELK stack installation..."
    local elasticsearch_status=$(ssh "$test_user@$test_ip" "systemctl is-active elasticsearch" 2>&1)
    local kibana_status=$(ssh "$test_user@$test_ip" "systemctl is-active kibana" 2>&1)
    local logstash_status=$(ssh "$test_user@$test_ip" "systemctl is-active logstash" 2>&1)
    
    if [ "$elasticsearch_status" = "active" ]; then
        assert_equals "$kibana_status" "active" "Kibana should be running if Elasticsearch is active"
        assert_equals "$logstash_status" "active" "Logstash should be running if Elasticsearch is active"
    fi
}

# Test log file permissions
test_log_permissions() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test /var/log permissions
    echo "Testing /var/log permissions..."
    local log_perms=$(ssh "$test_user@$test_ip" "stat -c %a /var/log" 2>&1)
    assert_equals "$log_perms" "755" "/var/log should have correct permissions"
    
    # Test syslog permissions
    echo "Testing syslog permissions..."
    local syslog_perms=$(ssh "$test_user@$test_ip" "stat -c %a /var/log/syslog" 2>&1)
    assert_equals "$syslog_perms" "640" "Syslog should have correct permissions"
    
    # Test auth.log permissions
    echo "Testing auth.log permissions..."
    local auth_perms=$(ssh "$test_user@$test_ip" "stat -c %a /var/log/auth.log" 2>&1)
    assert_equals "$auth_perms" "640" "Auth.log should have correct permissions"
}

# Test log rotation
test_log_rotation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test logrotate configuration
    echo "Testing logrotate configuration..."
    local logrotate_conf=$(ssh "$test_user@$test_ip" "cat /etc/logrotate.conf | grep -E 'rotate|size'" 2>&1)
    assert_contains "$logrotate_conf" "rotate" "Logrotate should be configured"
    
    # Test rotated logs existence
    echo "Testing rotated logs..."
    local rotated_logs=$(ssh "$test_user@$test_ip" "ls -l /var/log/syslog.1 2>/dev/null" 2>&1)
    assert_contains "$rotated_logs" "syslog.1" "Rotated logs should exist"
    
    # Test compressed logs
    echo "Testing compressed logs..."
    local compressed_logs=$(ssh "$test_user@$test_ip" "ls -l /var/log/*.gz 2>/dev/null" 2>&1)
    assert_contains "$compressed_logs" ".gz" "Compressed logs should exist"
}

# Test log forwarding
test_log_forwarding() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test rsyslog forwarding configuration
    echo "Testing rsyslog forwarding configuration..."
    local forward_conf=$(ssh "$test_user@$test_ip" "test -f /etc/rsyslog.d/50-forward.conf && echo 'exists'" 2>&1)
    assert_equals "$forward_conf" "exists" "Log forwarding configuration should exist"
    
    # Test logstash forwarding (if configured)
    echo "Testing logstash forwarding..."
    local logstash_conf=$(ssh "$test_user@$test_ip" "test -f /etc/logstash/conf.d/01-syslog.conf && echo 'exists'" 2>&1)
    if [ "$logstash_conf" = "exists" ]; then
        local logstash_pipeline=$(ssh "$test_user@$test_ip" "cat /etc/logstash/conf.d/01-syslog.conf" 2>&1)
        assert_contains "$logstash_pipeline" "input" "Logstash pipeline should be configured"
    fi
}

# Test log analysis
test_log_analysis() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test basic log analysis tools
    echo "Testing log analysis tools..."
    local analysis_tools=$(ssh "$test_user@$test_ip" "which awk grep sed" 2>&1)
    assert_not_empty "$analysis_tools" "Basic log analysis tools should be installed"
    
    # Test Elasticsearch indices (if configured)
    echo "Testing Elasticsearch indices..."
    if ssh "$test_user@$test_ip" "systemctl is-active elasticsearch" &>/dev/null; then
        local es_indices=$(ssh "$test_user@$test_ip" "curl -s localhost:9200/_cat/indices" 2>&1)
        assert_contains "$es_indices" "logstash" "Elasticsearch should have log indices"
    fi
}

# Run logging tests
run_logging_tests() {
    start_test_suite "Logging Tests"
    
    run_test "Logging Installation" test_logging_installation
    run_test "Log Permissions" test_log_permissions
    run_test "Log Rotation" test_log_rotation
    run_test "Log Forwarding" test_log_forwarding
    run_test "Log Analysis" test_log_analysis
    
    finish_test_suite
}

# Execute logging tests
run_logging_tests
