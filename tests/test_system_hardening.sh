#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test kernel parameters
test_kernel_parameters() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test sysctl security settings
    echo "Testing sysctl security settings..."
    
    # IP forwarding
    local ip_forward=$(ssh "$test_user@$test_ip" "sysctl net.ipv4.ip_forward" 2>&1)
    assert_contains "$ip_forward" "0" "IP forwarding should be disabled"
    
    # ICMP redirects
    local icmp_redirects=$(ssh "$test_user@$test_ip" "sysctl net.ipv4.conf.all.accept_redirects" 2>&1)
    assert_contains "$icmp_redirects" "0" "ICMP redirects should be disabled"
    
    # Source routing
    local source_route=$(ssh "$test_user@$test_ip" "sysctl net.ipv4.conf.all.accept_source_route" 2>&1)
    assert_contains "$source_route" "0" "Source routing should be disabled"
    
    # SYN cookies
    local syn_cookies=$(ssh "$test_user@$test_ip" "sysctl net.ipv4.tcp_syncookies" 2>&1)
    assert_contains "$syn_cookies" "1" "SYN cookies should be enabled"
}

# Test file system security
test_filesystem_security() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test /tmp mount options
    echo "Testing /tmp mount options..."
    local tmp_mount=$(ssh "$test_user@$test_ip" "mount | grep ' /tmp '" 2>&1)
    assert_contains "$tmp_mount" "noexec" "/tmp should be mounted with noexec"
    
    # Test sticky bit on world-writable directories
    echo "Testing sticky bit on world-writable directories..."
    local sticky_bit=$(ssh "$test_user@$test_ip" "find /tmp -type d -perm -0002 ! -perm -1000" 2>&1)
    assert_empty "$sticky_bit" "World-writable directories should have sticky bit"
    
    # Test SUID/SGID files
    echo "Testing SUID/SGID files..."
    local suid_files=$(ssh "$test_user@$test_ip" "find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; 2>/dev/null")
    assert_not_empty "$suid_files" "Should have controlled SUID/SGID files"
}

# Test password policies
test_password_policies() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test password complexity
    echo "Testing password complexity settings..."
    local pwd_complexity=$(ssh "$test_user@$test_ip" "grep pam_pwquality.so /etc/pam.d/common-password" 2>&1)
    assert_contains "$pwd_complexity" "minlen=12" "Password minimum length should be 12"
    
    # Test password aging
    echo "Testing password aging..."
    local pwd_aging=$(ssh "$test_user@$test_ip" "grep PASS_MAX_DAYS /etc/login.defs" 2>&1)
    assert_contains "$pwd_aging" "90" "Password maximum age should be 90 days"
    
    # Test account lockout
    echo "Testing account lockout..."
    local account_lockout=$(ssh "$test_user@$test_ip" "grep pam_tally2.so /etc/pam.d/common-auth" 2>&1)
    assert_contains "$account_lockout" "deny=5" "Account should lock after 5 failed attempts"
}

# Test process security
test_process_security() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test running services
    echo "Testing running services..."
    local services=$(ssh "$test_user@$test_ip" "systemctl list-units --type=service --state=running" 2>&1)
    assert_not_contains "$services" "telnet.service" "Telnet should not be running"
    
    # Test open ports
    echo "Testing open ports..."
    local open_ports=$(ssh "$test_user@$test_ip" "ss -tuln" 2>&1)
    assert_not_contains "$open_ports" ":23 " "Port 23 (telnet) should not be open"
    
    # Test process ownership
    echo "Testing process ownership..."
    local root_processes=$(ssh "$test_user@$test_ip" "ps aux | grep '^root' | grep -v '\['" 2>&1)
    assert_not_contains "$root_processes" "nginx" "Nginx should not run as root"
}

# Test audit configuration
test_audit_configuration() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test auditd installation
    echo "Testing auditd installation..."
    local auditd_status=$(ssh "$test_user@$test_ip" "systemctl is-active auditd" 2>&1)
    assert_equals "$auditd_status" "active" "Auditd should be running"
    
    # Test audit rules
    echo "Testing audit rules..."
    local audit_rules=$(ssh "$test_user@$test_ip" "auditctl -l" 2>&1)
    assert_contains "$audit_rules" "-w /etc/passwd" "Should audit password file changes"
    
    # Test audit log
    echo "Testing audit log..."
    local audit_log=$(ssh "$test_user@$test_ip" "test -f /var/log/audit/audit.log && echo 'exists'" 2>&1)
    assert_equals "$audit_log" "exists" "Audit log should exist"
}

# Run system hardening tests
run_system_hardening_tests() {
    start_test_suite "System Hardening Tests"
    
    run_test "Kernel Parameters" test_kernel_parameters
    run_test "Filesystem Security" test_filesystem_security
    run_test "Password Policies" test_password_policies
    run_test "Process Security" test_process_security
    run_test "Audit Configuration" test_audit_configuration
    
    finish_test_suite
}

# Execute system hardening tests
run_system_hardening_tests
