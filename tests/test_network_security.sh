#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test UFW configuration
test_ufw_setup() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test UFW installation
    echo "Testing UFW installation..."
    local ufw_result=$(ssh "$test_user@$test_ip" "which ufw" 2>&1)
    assert_not_empty "$ufw_result" "UFW should be installed"
    
    # Test UFW status
    echo "Testing UFW status..."
    local status_result=$(ssh "$test_user@$test_ip" "sudo ufw status" 2>&1)
    assert_contains "$status_result" "Status: active" "UFW should be active"
    
    # Test SSH port
    echo "Testing SSH port..."
    local ssh_result=$(ssh "$test_user@$test_ip" "sudo ufw status | grep 22" 2>&1)
    assert_contains "$ssh_result" "ALLOW" "SSH port should be allowed"
    
    # Test HTTP/HTTPS ports
    echo "Testing HTTP/HTTPS ports..."
    local http_result=$(ssh "$test_user@$test_ip" "sudo ufw status | grep 80" 2>&1)
    assert_contains "$http_result" "ALLOW" "HTTP port should be allowed"
    local https_result=$(ssh "$test_user@$test_ip" "sudo ufw status | grep 443" 2>&1)
    assert_contains "$https_result" "ALLOW" "HTTPS port should be allowed"
}

# Test Fail2Ban configuration
test_fail2ban_setup() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Fail2Ban installation
    echo "Testing Fail2Ban installation..."
    local f2b_result=$(ssh "$test_user@$test_ip" "which fail2ban-client" 2>&1)
    assert_not_empty "$f2b_result" "Fail2Ban should be installed"
    
    # Test Fail2Ban status
    echo "Testing Fail2Ban status..."
    local status_result=$(ssh "$test_user@$test_ip" "sudo fail2ban-client status" 2>&1)
    assert_contains "$status_result" "Number of jail:" "Fail2Ban should be running"
    
    # Test SSH jail
    echo "Testing SSH jail..."
    local ssh_jail=$(ssh "$test_user@$test_ip" "sudo fail2ban-client status sshd" 2>&1)
    assert_contains "$ssh_jail" "Status" "SSH jail should be configured"
    
    # Test jail configuration
    echo "Testing jail configuration..."
    local config_result=$(ssh "$test_user@$test_ip" "sudo cat /etc/fail2ban/jail.local" 2>&1)
    assert_contains "$config_result" "bantime" "Jail configuration should exist"
}

# Test SSH hardening
test_ssh_hardening() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SSH configuration
    echo "Testing SSH configuration..."
    local config=$(ssh "$test_user@$test_ip" "sudo cat /etc/ssh/sshd_config" 2>&1)
    
    # Check key authentication
    assert_contains "$config" "PubkeyAuthentication yes" "Public key authentication should be enabled"
    
    # Check password authentication
    assert_contains "$config" "PasswordAuthentication no" "Password authentication should be disabled"
    
    # Check root login
    assert_contains "$config" "PermitRootLogin no" "Root login should be disabled"
    
    # Check SSH protocol
    assert_contains "$config" "Protocol 2" "Only SSH protocol 2 should be allowed"
}

# Test network hardening
test_network_hardening() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test system configuration
    echo "Testing system configuration..."
    local sysctl=$(ssh "$test_user@$test_ip" "sudo sysctl -a" 2>&1)
    
    # Check IP forwarding
    assert_contains "$sysctl" "net.ipv4.ip_forward = 0" "IP forwarding should be disabled"
    
    # Check SYN flood protection
    assert_contains "$sysctl" "net.ipv4.tcp_syncookies = 1" "SYN flood protection should be enabled"
    
    # Check ICMP redirects
    assert_contains "$sysctl" "net.ipv4.conf.all.accept_redirects = 0" "ICMP redirects should be disabled"
}

# Test SSL/TLS configuration
test_ssl_configuration() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Nginx SSL configuration
    echo "Testing Nginx SSL configuration..."
    local nginx_conf=$(ssh "$test_user@$test_ip" "sudo cat /etc/nginx/sites-enabled/default" 2>&1)
    
    # Check SSL protocols
    assert_contains "$nginx_conf" "ssl_protocols TLSv1.2 TLSv1.3" "Only secure SSL protocols should be enabled"
    
    # Check SSL ciphers
    assert_contains "$nginx_conf" "ssl_prefer_server_ciphers on" "Server should prefer its own cipher order"
    
    # Check HSTS
    assert_contains "$nginx_conf" "Strict-Transport-Security" "HSTS should be enabled"
}

# Run network security tests
run_network_security_tests() {
    start_test_suite "Network Security Tests"
    
    run_test "UFW Setup" test_ufw_setup
    run_test "Fail2Ban Setup" test_fail2ban_setup
    run_test "SSH Hardening" test_ssh_hardening
    run_test "Network Hardening" test_network_hardening
    run_test "SSL Configuration" test_ssl_configuration
    
    finish_test_suite
}

# Execute network security tests
run_network_security_tests
