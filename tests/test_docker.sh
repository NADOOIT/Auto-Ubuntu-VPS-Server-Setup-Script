#!/bin/bash

# Import test framework
source "$(dirname "$0")/test_framework.sh"

# Test Docker installation
test_docker_installation() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Docker installation
    echo "Testing Docker installation..."
    local docker_result=$(ssh "$test_user@$test_ip" "which docker" 2>&1)
    assert_not_empty "$docker_result" "Docker should be installed"
    
    # Test Docker service
    echo "Testing Docker service..."
    local service_result=$(ssh "$test_user@$test_ip" "sudo systemctl status docker" 2>&1)
    assert_contains "$service_result" "active (running)" "Docker service should be running"
    
    # Test Docker permissions
    echo "Testing Docker permissions..."
    local perm_result=$(ssh "$test_user@$test_ip" "groups | grep docker" 2>&1)
    assert_contains "$perm_result" "docker" "User should be in docker group"
}

# Test Portainer setup
test_portainer_setup() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test Portainer container
    echo "Testing Portainer container..."
    local container_result=$(ssh "$test_user@$test_ip" "docker ps | grep portainer" 2>&1)
    assert_contains "$container_result" "portainer/portainer-ce" "Portainer container should be running"
    
    # Test Portainer volume
    echo "Testing Portainer volume..."
    local volume_result=$(ssh "$test_user@$test_ip" "docker volume ls | grep portainer_data" 2>&1)
    assert_contains "$volume_result" "portainer_data" "Portainer data volume should exist"
    
    # Test Portainer web interface
    echo "Testing Portainer web interface..."
    local web_result=$(ssh "$test_user@$test_ip" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9000" 2>&1)
    assert_equals "$web_result" "200" "Portainer web interface should be accessible"
}

# Test Docker network setup
test_docker_network() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test default networks
    echo "Testing default networks..."
    local networks_result=$(ssh "$test_user@$test_ip" "docker network ls" 2>&1)
    assert_contains "$networks_result" "bridge" "Bridge network should exist"
    assert_contains "$networks_result" "host" "Host network should exist"
    
    # Test custom network
    echo "Testing custom network..."
    local custom_result=$(ssh "$test_user@$test_ip" "docker network create test-network && docker network ls | grep test-network" 2>&1)
    assert_contains "$custom_result" "test-network" "Should be able to create custom network"
    
    # Cleanup test network
    ssh "$test_user@$test_ip" "docker network rm test-network" > /dev/null 2>&1
}

# Test Docker volume management
test_volume_management() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test volume creation
    echo "Testing volume creation..."
    local create_result=$(ssh "$test_user@$test_ip" "docker volume create test-volume && docker volume ls | grep test-volume" 2>&1)
    assert_contains "$create_result" "test-volume" "Should be able to create volume"
    
    # Test volume inspection
    echo "Testing volume inspection..."
    local inspect_result=$(ssh "$test_user@$test_ip" "docker volume inspect test-volume" 2>&1)
    assert_contains "$inspect_result" "Mountpoint" "Should be able to inspect volume"
    
    # Cleanup test volume
    ssh "$test_user@$test_ip" "docker volume rm test-volume" > /dev/null 2>&1
}

# Test Docker image management
test_image_management() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test image pull
    echo "Testing image pull..."
    local pull_result=$(ssh "$test_user@$test_ip" "docker pull hello-world" 2>&1)
    assert_contains "$pull_result" "Downloaded" "Should be able to pull images"
    
    # Test image list
    echo "Testing image list..."
    local list_result=$(ssh "$test_user@$test_ip" "docker images" 2>&1)
    assert_contains "$list_result" "hello-world" "Should be able to list images"
    
    # Test image removal
    echo "Testing image removal..."
    local remove_result=$(ssh "$test_user@$test_ip" "docker rmi hello-world" 2>&1)
    assert_contains "$remove_result" "Untagged" "Should be able to remove images"
}

# Test Docker container management
test_container_management() {
    local test_ip="$TEST_SERVER_HOST"
    local test_user="$TEST_SERVER_USER"
    
    # Test container creation
    echo "Testing container creation..."
    local create_result=$(ssh "$test_user@$test_ip" "docker run -d --name test-container nginx" 2>&1)
    assert_not_empty "$create_result" "Should be able to create container"
    
    # Test container list
    echo "Testing container list..."
    local list_result=$(ssh "$test_user@$test_ip" "docker ps | grep test-container" 2>&1)
    assert_contains "$list_result" "nginx" "Should be able to list containers"
    
    # Test container logs
    echo "Testing container logs..."
    local logs_result=$(ssh "$test_user@$test_ip" "docker logs test-container" 2>&1)
    assert_not_empty "$logs_result" "Should be able to view container logs"
    
    # Test container stop
    echo "Testing container stop..."
    local stop_result=$(ssh "$test_user@$test_ip" "docker stop test-container" 2>&1)
    assert_contains "$stop_result" "test-container" "Should be able to stop container"
    
    # Cleanup test container
    ssh "$test_user@$test_ip" "docker rm test-container" > /dev/null 2>&1
}

# Run Docker tests
run_docker_tests() {
    start_test_suite "Docker Integration Tests"
    
    run_test "Docker Installation" test_docker_installation
    run_test "Portainer Setup" test_portainer_setup
    run_test "Docker Network" test_docker_network
    run_test "Volume Management" test_volume_management
    run_test "Image Management" test_image_management
    run_test "Container Management" test_container_management
    
    finish_test_suite
}

# Execute Docker tests
run_docker_tests
