#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test SSL certificate installation
test_ssl_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    local domain="test.nadooit.de"
    
    # Test certbot installation
    echo "Testing certbot installation..."
    local certbot_result=$(ssh "$test_user@$test_ip" "which certbot" 2>&1)
    assert_not_empty "$certbot_result" "Certbot should be installed"
    
    # Test certificate creation
    echo "Testing certificate creation..."
    local cert_result=$(ssh "$test_user@$test_ip" "sudo certbot certificates" 2>&1)
    assert_contains "$cert_result" "$domain" "SSL certificate should exist for domain"
    
    # Test certificate permissions
    echo "Testing certificate permissions..."
    local perm_result=$(ssh "$test_user@$test_ip" "sudo ls -l /etc/letsencrypt/live/$domain/" 2>&1)
    assert_contains "$perm_result" "root root" "Certificate files should be owned by root"
}

# Test Nginx SSL configuration
test_nginx_ssl() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    local domain="test.nadooit.de"
    
    # Test Nginx SSL configuration
    echo "Testing Nginx SSL configuration..."
    local config=$(ssh "$test_user@$test_ip" "sudo cat /etc/nginx/sites-enabled/$domain" 2>&1)
    
    # Check SSL certificate paths
    assert_contains "$config" "ssl_certificate" "SSL certificate path should be configured"
    assert_contains "$config" "ssl_certificate_key" "SSL certificate key path should be configured"
    
    # Check SSL parameters
    assert_contains "$config" "ssl_session_timeout" "SSL session timeout should be configured"
    assert_contains "$config" "ssl_session_cache" "SSL session cache should be configured"
}

# Test SSL renewal
test_ssl_renewal() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test renewal configuration
    echo "Testing renewal configuration..."
    local renewal_conf=$(ssh "$test_user@$test_ip" "sudo cat /etc/letsencrypt/renewal/test.nadooit.de.conf" 2>&1)
    assert_contains "$renewal_conf" "authenticator = nginx" "Renewal configuration should exist"
    
    # Test renewal hook
    echo "Testing renewal hook..."
    local hook_result=$(ssh "$test_user@$test_ip" "sudo ls /etc/letsencrypt/renewal-hooks/deploy/" 2>&1)
    assert_not_empty "$hook_result" "Renewal hook should exist"
    
    # Test renewal timer
    echo "Testing renewal timer..."
    local timer_result=$(ssh "$test_user@$test_ip" "sudo systemctl status certbot.timer" 2>&1)
    assert_contains "$timer_result" "active" "Renewal timer should be active"
}

# Test SSL security headers
test_security_headers() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test security headers in Nginx configuration
    echo "Testing security headers..."
    local headers=$(ssh "$test_user@$test_ip" "curl -sI https://test.nadooit.de" 2>&1)
    
    # Check HSTS
    assert_contains "$headers" "Strict-Transport-Security" "HSTS header should be present"
    
    # Check XSS protection
    assert_contains "$headers" "X-XSS-Protection" "XSS protection header should be present"
    
    # Check content type options
    assert_contains "$headers" "X-Content-Type-Options" "Content type options header should be present"
    
    # Check frame options
    assert_contains "$headers" "X-Frame-Options" "Frame options header should be present"
}

# Test SSL performance
test_ssl_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SSL session resumption
    echo "Testing SSL session resumption..."
    local resumption=$(ssh "$test_user@$test_ip" "echo 'Q' | openssl s_client -connect test.nadooit.de:443 -reconnect" 2>&1)
    assert_contains "$resumption" "Reused" "SSL session resumption should work"
    
    # Test SSL stapling
    echo "Testing OCSP stapling..."
    local stapling=$(ssh "$test_user@$test_ip" "echo 'Q' | openssl s_client -connect test.nadooit.de:443 -status" 2>&1)
    assert_contains "$stapling" "OCSP Response Status" "OCSP stapling should be enabled"
}

# Run SSL tests
run_ssl_tests() {
    start_test_suite "SSL/TLS Tests"
    
    run_test "SSL Installation" test_ssl_installation
    run_test "Nginx SSL Configuration" test_nginx_ssl
    run_test "SSL Renewal" test_ssl_renewal
    run_test "Security Headers" test_security_headers
    run_test "SSL Performance" test_ssl_performance
    
    finish_test_suite
}

# Execute SSL tests
run_ssl_tests
