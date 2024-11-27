#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test FIDO2 authentication
test_fido2_setup() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test FIDO2 installation
    echo "Testing FIDO2 installation..."
    local install_result=$(setup_fido2 "$test_ip" "$test_user" 2>&1)
    assert_contains "$install_result" "FIDO2 setup complete" "FIDO2 should install successfully"
    
    # Test PAM configuration
    echo "Testing PAM configuration..."
    local pam_result=$(ssh "$test_user@$test_ip" "grep 'pam_u2f.so' /etc/pam.d/common-auth" 2>&1)
    assert_not_empty "$pam_result" "PAM configuration should include U2F"
    
    # Test key registration
    echo "Testing key registration..."
    local key_result=$(register_security_key "$test_ip" "$test_user" 2>&1)
    assert_contains "$key_result" "registered" "Security key should register successfully"
}

# Test Windows Hello authentication
test_windows_hello() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test Windows Hello setup
    echo "Testing Windows Hello setup..."
    local setup_result=$(setup_windows_hello "$test_ip" "$test_user" 2>&1)
    assert_contains "$setup_result" "Windows Hello setup complete" "Windows Hello should setup successfully"
    
    # Test credential storage
    echo "Testing credential storage..."
    local cred_result=$(check_credential_storage "$test_ip" "$test_user" 2>&1)
    assert_contains "$cred_result" "configured" "Credential storage should be configured"
}

# Test passkey authentication
test_passkey_setup() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test passkey setup
    echo "Testing passkey setup..."
    local setup_result=$(setup_passkeys "$test_ip" "$test_user" 2>&1)
    assert_contains "$setup_result" "Passkey setup complete" "Passkey should setup successfully"
    
    # Test WebAuthn configuration
    echo "Testing WebAuthn configuration..."
    local webauthn_result=$(check_webauthn_config "$test_ip" "$test_user" 2>&1)
    assert_contains "$webauthn_result" "configured" "WebAuthn should be configured"
}

# Test multi-factor authentication
test_mfa_setup() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test MFA configuration
    echo "Testing MFA configuration..."
    local mfa_result=$(setup_mfa "$test_ip" "$test_user" 2>&1)
    assert_contains "$mfa_result" "MFA setup complete" "MFA should setup successfully"
    
    # Test authentication methods
    echo "Testing authentication methods..."
    local methods_result=$(list_auth_methods "$test_ip" "$test_user" 2>&1)
    assert_contains "$methods_result" "FIDO2" "Authentication methods should include FIDO2"
    assert_contains "$methods_result" "Windows Hello" "Authentication methods should include Windows Hello"
    assert_contains "$methods_result" "Passkey" "Authentication methods should include Passkey"
}

# Test authentication recovery
test_auth_recovery() {
    local test_ip="127.0.0.1"
    local test_user="test_admin"
    
    # Test backup codes
    echo "Testing backup codes..."
    local backup_result=$(generate_backup_codes "$test_ip" "$test_user" 2>&1)
    assert_contains "$backup_result" "generated" "Backup codes should be generated"
    
    # Test recovery process
    echo "Testing recovery process..."
    local recovery_result=$(test_recovery_process "$test_ip" "$test_user" 2>&1)
    assert_contains "$recovery_result" "successful" "Recovery process should be successful"
}

# Run authentication tests
run_auth_tests() {
    start_test_suite "Authentication Tests"
    
    run_test "FIDO2 Setup" test_fido2_setup
    run_test "Windows Hello" test_windows_hello
    run_test "Passkey Setup" test_passkey_setup
    run_test "Multi-Factor Authentication" test_mfa_setup
    run_test "Authentication Recovery" test_auth_recovery
    
    finish_test_suite
}

# Execute authentication tests
run_auth_tests
