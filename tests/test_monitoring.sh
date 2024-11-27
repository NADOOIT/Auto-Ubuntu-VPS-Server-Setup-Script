#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test monitoring system installation
test_monitoring_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test node_exporter installation
    echo "Testing node_exporter installation..."
    local node_exporter_status=$(ssh "$test_user@$test_ip" "systemctl is-active node_exporter" 2>&1)
    assert_equals "$node_exporter_status" "active" "node_exporter should be running"
    
    # Test prometheus installation
    echo "Testing prometheus installation..."
    local prometheus_status=$(ssh "$test_user@$test_ip" "systemctl is-active prometheus" 2>&1)
    assert_equals "$prometheus_status" "active" "Prometheus should be running"
    
    # Test grafana installation
    echo "Testing grafana installation..."
    local grafana_status=$(ssh "$test_user@$test_ip" "systemctl is-active grafana-server" 2>&1)
    assert_equals "$grafana_status" "active" "Grafana should be running"
}

# Test monitoring endpoints
test_monitoring_endpoints() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test node_exporter metrics endpoint
    echo "Testing node_exporter metrics endpoint..."
    local node_metrics=$(ssh "$test_user@$test_ip" "curl -s http://localhost:9100/metrics | head -n 1" 2>&1)
    assert_contains "$node_metrics" "node_" "node_exporter metrics should be accessible"
    
    # Test prometheus endpoint
    echo "Testing prometheus endpoint..."
    local prom_metrics=$(ssh "$test_user@$test_ip" "curl -s http://localhost:9090/-/healthy" 2>&1)
    assert_equals "$prom_metrics" "Prometheus Server is Healthy." "Prometheus endpoint should be accessible"
    
    # Test grafana endpoint
    echo "Testing grafana endpoint..."
    local grafana_status=$(ssh "$test_user@$test_ip" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000" 2>&1)
    assert_equals "$grafana_status" "200" "Grafana endpoint should be accessible"
}

# Test monitoring data collection
test_monitoring_data() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test prometheus target status
    echo "Testing prometheus targets..."
    local targets=$(ssh "$test_user@$test_ip" "curl -s http://localhost:9090/api/v1/targets | grep 'health'" 2>&1)
    assert_contains "$targets" "up" "Prometheus targets should be up"
    
    # Test prometheus data collection
    echo "Testing prometheus data collection..."
    local query_result=$(ssh "$test_user@$test_ip" "curl -s 'http://localhost:9090/api/v1/query?query=up'" 2>&1)
    assert_contains "$query_result" "success" "Prometheus should collect metrics successfully"
}

# Test alert configuration
test_alert_config() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test alertmanager configuration
    echo "Testing alertmanager configuration..."
    local alertmanager_config=$(ssh "$test_user@$test_ip" "test -f /etc/prometheus/alertmanager.yml && echo 'exists'" 2>&1)
    assert_equals "$alertmanager_config" "exists" "Alertmanager config should exist"
    
    # Test alert rules
    echo "Testing alert rules..."
    local alert_rules=$(ssh "$test_user@$test_ip" "test -f /etc/prometheus/rules.yml && echo 'exists'" 2>&1)
    assert_equals "$alert_rules" "exists" "Alert rules should exist"
}

# Test dashboard configuration
test_dashboard_config() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test grafana datasource
    echo "Testing grafana datasource..."
    local datasource=$(ssh "$test_user@$test_ip" "curl -s -H 'Content-Type: application/json' -u admin:admin http://localhost:3000/api/datasources" 2>&1)
    assert_contains "$datasource" "prometheus" "Grafana should have Prometheus datasource configured"
    
    # Test grafana dashboard
    echo "Testing grafana dashboard..."
    local dashboard=$(ssh "$test_user@$test_ip" "curl -s -H 'Content-Type: application/json' -u admin:admin http://localhost:3000/api/dashboards" 2>&1)
    assert_contains "$dashboard" "title" "Grafana should have dashboards configured"
}

# Run monitoring tests
run_monitoring_tests() {
    start_test_suite "Monitoring Tests"
    
    run_test "Monitoring Installation" test_monitoring_installation
    run_test "Monitoring Endpoints" test_monitoring_endpoints
    run_test "Monitoring Data Collection" test_monitoring_data
    run_test "Alert Configuration" test_alert_config
    run_test "Dashboard Configuration" test_dashboard_config
    
    finish_test_suite
}

# Execute monitoring tests
run_monitoring_tests
