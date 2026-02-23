#!/bin/bash

# Function to execute Docker Compose pull and up commands
execute_docker_commands() {
    local config_file=""
    local containers=""

    # Parse command line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --config)
                config_file="$2"
                shift
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
        shift
    done

    if [ -z "$config_file" ]; then
        echo "Please provide a Docker Compose config file using --config."
        exit 1
    fi

    
    containers=$(docker ps --format "{{.Names}}")

    # Pull images
    if docker compose -f "$config_file" pull; then
        # If pull successful, bring containers up
        docker compose -f "$config_file" up -d $containers
        # Delete unused images
        docker image prune -f > /dev/null        
    else
        # If pull fails, display error and exit
        echo "Failed to pull Docker images or bring containers up."
        exit 1
    fi
}

execute_docker_commands "$@"