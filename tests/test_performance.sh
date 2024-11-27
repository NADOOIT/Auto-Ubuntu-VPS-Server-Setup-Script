#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test system performance metrics
test_system_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test CPU load
    echo "Testing CPU load..."
    local cpu_load=$(ssh "$test_user@$test_ip" "uptime | awk -F'load average:' '{ print \$2 }' | awk '{ print \$1 }'" 2>&1)
    assert_length_greater_than "$cpu_load" 0 "CPU load should be measurable"
    
    # Test memory usage
    echo "Testing memory usage..."
    local mem_free=$(ssh "$test_user@$test_ip" "free -m | grep Mem | awk '{ print \$4 }'" 2>&1)
    assert_length_greater_than "$mem_free" 100 "Should have sufficient free memory"
    
    # Test disk usage
    echo "Testing disk usage..."
    local disk_free=$(ssh "$test_user@$test_ip" "df -h / | tail -1 | awk '{ print \$4 }'" 2>&1)
    assert_contains "$disk_free" "G" "Should have sufficient disk space"
}

# Test network performance
test_network_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test network latency
    echo "Testing network latency..."
    local ping_result=$(ssh "$test_user@$test_ip" "ping -c 1 8.8.8.8 | grep 'time=' | cut -d '=' -f 4" 2>&1)
    assert_contains "$ping_result" "ms" "Network latency should be measurable"
    
    # Test network throughput
    echo "Testing network throughput..."
    local speed_test=$(ssh "$test_user@$test_ip" "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - --simple" 2>&1)
    assert_contains "$speed_test" "Download" "Network speed test should complete"
}

# Test Docker performance
test_docker_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Docker container startup time
    echo "Testing Docker container startup time..."
    local start_time=$(date +%s%N)
    ssh "$test_user@$test_ip" "docker run --rm hello-world" > /dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$((($end_time - $start_time)/1000000))
    assert_length_greater_than "$duration" 0 "Container startup time should be measurable"
    
    # Test Docker build performance
    echo "Testing Docker build performance..."
    local dockerfile='FROM ubuntu:22.04\nRUN apt-get update'
    ssh "$test_user@$test_ip" "echo -e '$dockerfile' > Dockerfile"
    local build_time=$(ssh "$test_user@$test_ip" "time docker build -t test-image . 2>&1 | grep real" 2>&1)
    assert_contains "$build_time" "real" "Docker build time should be measurable"
}

# Test SSL/TLS performance
test_ssl_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    local domain="test.nadooit.de"
    
    # Test SSL handshake time
    echo "Testing SSL handshake time..."
    local handshake_time=$(ssh "$test_user@$test_ip" "echo 'Q' | time openssl s_client -connect $domain:443 2>&1 | grep real" 2>&1)
    assert_contains "$handshake_time" "real" "SSL handshake time should be measurable"
    
    # Test SSL session reuse
    echo "Testing SSL session reuse..."
    local reuse_result=$(ssh "$test_user@$test_ip" "echo 'Q' | openssl s_client -connect $domain:443 -reconnect 2>&1" 2>&1)
    assert_contains "$reuse_result" "Reused" "SSL session reuse should be enabled"
}

# Run performance tests
run_performance_tests() {
    start_test_suite "Performance Tests"
    
    run_test "System Performance" test_system_performance
    run_test "Network Performance" test_network_performance
    run_test "Docker Performance" test_docker_performance
    run_test "SSL Performance" test_ssl_performance
    
    finish_test_suite
}

# Execute performance tests
run_performance_tests
