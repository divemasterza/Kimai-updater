#!/bin/bash

# Check if current directory is a git repository
if [ ! -d ".git" ]; then
    echo "Error: This is not a git repository."
    exit 1
fi

# Function to check the last command's status
check_command_status() {
    if [ $? -ne 0 ]; then
        echo "Error: Previous command failed. Exiting."
        exit 1
    fi
}

# Prompt user for confirmation
read -p "Do you want to proceed with the upgrade? (y/n): " response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
    echo "Fetching updates..."
    git fetch --tags
    check_command_status

    current_version=$(git describe --tags)
    echo "Current version: $current_version"

    tags=$(git tag | sort -V | tail -n 5)
    echo "Available versions:"
    select version in $tags; do
        if [[ -n $version ]]; then
            echo "Selected version: $version"
            break
        else
            echo "Invalid selection"
        fi
    done

    git checkout $version
    check_command_status

    echo "Installing dependencies..."
    composer install --optimize-autoloader -n
    check_command_status

    bin/console kimai:update
    check_command_status

    read -p "Do you want to fix the permissions? (y/n): " fix_permissions

    if [[ "$fix_permissions" == "y" || "$fix_permissions" == "Y" ]]; then
        while true; do
            read -p "Enter the owner (e.g., username:group) or type 'exit' to quit: " owner

            if [[ "$owner" == "exit" ]]; then
                exit 0
            fi

            username=${owner%:*}
            group=${owner#*:}

            if id "$username" &>/dev/null && grep -q "^$group:" /etc/group; then
                chown -Rv $owner *
                break
            else
                echo "Error: Specified owner or group does not exist. Please try again."
            fi
        done
    fi

    echo "Upgrade to $version successful."

else
    echo "Upgrade aborted."
fi
