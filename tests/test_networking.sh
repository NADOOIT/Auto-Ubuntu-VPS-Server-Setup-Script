#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test network interfaces
test_network_interfaces() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test interface status
    echo "Testing network interface status..."
    local interface_status=$(ssh "$test_user@$test_ip" "ip link show" 2>&1)
    assert_contains "$interface_status" "state UP" "Network interface should be up"
    
    # Test interface configuration
    echo "Testing interface configuration..."
    local interface_config=$(ssh "$test_user@$test_ip" "ip addr show" 2>&1)
    assert_contains "$interface_config" "inet" "Interface should have IP address"
    
    # Test MTU settings
    echo "Testing MTU settings..."
    local mtu_settings=$(ssh "$test_user@$test_ip" "ip link show | grep mtu" 2>&1)
    assert_contains "$mtu_settings" "1500" "MTU should be properly set"
}

# Test network routing
test_network_routing() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test default route
    echo "Testing default route..."
    local default_route=$(ssh "$test_user@$test_ip" "ip route show default" 2>&1)
    assert_contains "$default_route" "default via" "Default route should be configured"
    
    # Test routing table
    echo "Testing routing table..."
    local routing_table=$(ssh "$test_user@$test_ip" "ip route show" 2>&1)
    assert_not_empty "$routing_table" "Routing table should not be empty"
    
    # Test route to Google DNS
    echo "Testing route to Google DNS..."
    local google_route=$(ssh "$test_user@$test_ip" "traceroute -n 8.8.8.8" 2>&1)
    assert_contains "$google_route" "8.8.8.8" "Should have route to Google DNS"
}

# Test DNS configuration
test_dns_configuration() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test resolv.conf
    echo "Testing resolv.conf..."
    local resolv_conf=$(ssh "$test_user@$test_ip" "cat /etc/resolv.conf" 2>&1)
    assert_contains "$resolv_conf" "nameserver" "Should have nameserver configured"
    
    # Test DNS resolution
    echo "Testing DNS resolution..."
    local dns_resolution=$(ssh "$test_user@$test_ip" "host google.com" 2>&1)
    assert_contains "$dns_resolution" "has address" "Should resolve domain names"
    
    # Test reverse DNS
    echo "Testing reverse DNS..."
    local reverse_dns=$(ssh "$test_user@$test_ip" "host 8.8.8.8" 2>&1)
    assert_contains "$reverse_dns" "dns.google" "Should resolve reverse DNS"
}

# Test network performance
test_network_performance() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test network latency
    echo "Testing network latency..."
    local latency=$(ssh "$test_user@$test_ip" "ping -c 4 8.8.8.8 | tail -1" 2>&1)
    assert_contains "$latency" "ms" "Should have reasonable latency"
    
    # Test bandwidth
    echo "Testing bandwidth..."
    local bandwidth=$(ssh "$test_user@$test_ip" "iperf3 -c iperf.he.net -t 5" 2>&1)
    assert_contains "$bandwidth" "Mbits/sec" "Should have reasonable bandwidth"
    
    # Test packet loss
    echo "Testing packet loss..."
    local packet_loss=$(ssh "$test_user@$test_ip" "ping -c 100 8.8.8.8 | grep 'packet loss'" 2>&1)
    assert_contains "$packet_loss" "0% packet loss" "Should have no packet loss"
}

# Test network security
test_network_security() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test firewall rules
    echo "Testing firewall rules..."
    local firewall_rules=$(ssh "$test_user@$test_ip" "iptables -L" 2>&1)
    assert_contains "$firewall_rules" "REJECT" "Should have reject rules"
    
    # Test TCP wrappers
    echo "Testing TCP wrappers..."
    local tcp_wrappers=$(ssh "$test_user@$test_ip" "cat /etc/hosts.deny" 2>&1)
    assert_contains "$tcp_wrappers" "ALL: ALL" "Should deny by default"
    
    # Test port security
    echo "Testing port security..."
    local open_ports=$(ssh "$test_user@$test_ip" "netstat -tuln" 2>&1)
    assert_not_contains "$open_ports" ":23" "Telnet port should be closed"
}

# Test network monitoring
test_network_monitoring() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test netstat
    echo "Testing netstat..."
    local netstat_output=$(ssh "$test_user@$test_ip" "netstat -s" 2>&1)
    assert_not_empty "$netstat_output" "Should have network statistics"
    
    # Test tcpdump
    echo "Testing tcpdump..."
    local tcpdump_output=$(ssh "$test_user@$test_ip" "timeout 5 tcpdump -i any -c 10 2>&1")
    assert_contains "$tcpdump_output" "packets" "Should capture packets"
    
    # Test network graphs
    echo "Testing network graphs..."
    local vnstat_output=$(ssh "$test_user@$test_ip" "vnstat -h" 2>&1)
    assert_contains "$vnstat_output" "rx" "Should track network usage"
}

# Run networking tests
run_networking_tests() {
    start_test_suite "Networking Tests"
    
    run_test "Network Interfaces" test_network_interfaces
    run_test "Network Routing" test_network_routing
    run_test "DNS Configuration" test_dns_configuration
    run_test "Network Performance" test_network_performance
    run_test "Network Security" test_network_security
    run_test "Network Monitoring" test_network_monitoring
    
    finish_test_suite
}

# Execute networking tests
run_networking_tests
