#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test mail server installation
test_mail_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test postfix installation
    echo "Testing postfix installation..."
    local postfix_status=$(ssh "$test_user@$test_ip" "systemctl is-active postfix" 2>&1)
    assert_equals "$postfix_status" "active" "Postfix should be running"
    
    # Test dovecot installation
    echo "Testing dovecot installation..."
    local dovecot_status=$(ssh "$test_user@$test_ip" "systemctl is-active dovecot" 2>&1)
    assert_equals "$dovecot_status" "active" "Dovecot should be running"
    
    # Test SpamAssassin installation
    echo "Testing SpamAssassin installation..."
    local spamassassin_status=$(ssh "$test_user@$test_ip" "systemctl is-active spamassassin" 2>&1)
    assert_equals "$spamassassin_status" "active" "SpamAssassin should be running"
}

# Test mail configuration
test_mail_config() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test postfix configuration
    echo "Testing postfix configuration..."
    local postfix_config=$(ssh "$test_user@$test_ip" "postconf -n | grep 'myhostname'" 2>&1)
    assert_contains "$postfix_config" "myhostname" "Postfix should be configured"
    
    # Test dovecot configuration
    echo "Testing dovecot configuration..."
    local dovecot_config=$(ssh "$test_user@$test_ip" "test -f /etc/dovecot/dovecot.conf && echo 'exists'" 2>&1)
    assert_equals "$dovecot_config" "exists" "Dovecot config should exist"
    
    # Test SSL configuration
    echo "Testing mail SSL configuration..."
    local ssl_config=$(ssh "$test_user@$test_ip" "postconf -n | grep 'smtpd_tls_cert_file'" 2>&1)
    assert_contains "$ssl_config" "letsencrypt" "Mail SSL should be configured"
}

# Test mail functionality
test_mail_functionality() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SMTP connection
    echo "Testing SMTP connection..."
    local smtp_test=$(ssh "$test_user@$test_ip" "nc -zv localhost 25 2>&1")
    assert_contains "$smtp_test" "open" "SMTP port should be open"
    
    # Test IMAP connection
    echo "Testing IMAP connection..."
    local imap_test=$(ssh "$test_user@$test_ip" "nc -zv localhost 143 2>&1")
    assert_contains "$imap_test" "open" "IMAP port should be open"
    
    # Test secure SMTP connection
    echo "Testing secure SMTP connection..."
    local smtps_test=$(ssh "$test_user@$test_ip" "nc -zv localhost 465 2>&1")
    assert_contains "$smtps_test" "open" "SMTPS port should be open"
}

# Test spam protection
test_spam_protection() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test SpamAssassin configuration
    echo "Testing SpamAssassin configuration..."
    local spamassassin_config=$(ssh "$test_user@$test_ip" "test -f /etc/spamassassin/local.cf && echo 'exists'" 2>&1)
    assert_equals "$spamassassin_config" "exists" "SpamAssassin config should exist"
    
    # Test spam learning database
    echo "Testing spam learning database..."
    local bayes_db=$(ssh "$test_user@$test_ip" "test -f /var/lib/spamassassin/bayes_toks && echo 'exists'" 2>&1)
    assert_equals "$bayes_db" "exists" "Spam learning database should exist"
}

# Test mail backup
test_mail_backup() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test mail directory backup
    echo "Testing mail directory backup..."
    local mail_backup=$(ssh "$test_user@$test_ip" "test -d /var/mail/backup && echo 'exists'" 2>&1)
    assert_equals "$mail_backup" "exists" "Mail backup directory should exist"
    
    # Test mail configuration backup
    echo "Testing mail configuration backup..."
    local config_backup=$(ssh "$test_user@$test_ip" "test -f /etc/postfix/backup/main.cf && echo 'exists'" 2>&1)
    assert_equals "$config_backup" "exists" "Mail configuration backup should exist"
}

# Run mail server tests
run_mail_tests() {
    start_test_suite "Mail Server Tests"
    
    run_test "Mail Installation" test_mail_installation
    run_test "Mail Configuration" test_mail_config
    run_test "Mail Functionality" test_mail_functionality
    run_test "Spam Protection" test_spam_protection
    run_test "Mail Backup" test_mail_backup
    
    finish_test_suite
}

# Execute mail server tests
run_mail_tests
