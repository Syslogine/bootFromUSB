#!/bin/bash
#
# Script to copy the root directory to a specified destination volume or directory
#
# Copyright (c) 2016-24 Jetsonhacks
# MIT License

# Set default values
destination_path=""
volume_label=""
device_path=""

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "  -d, --directory <directory>  Directory path to the destination"
    echo "  -p, --path <path>            Device path (e.g., /dev/sda1)"
    echo "  -v, --volume-label <label>   Name of the volume label"
    echo "  -h, --help                   Display this help message"
}

# Parse command-line arguments using getopts
while getopts ":d:p:v:h" opt; do
    case $opt in
        d)
            destination_path="$OPTARG"
            ;;
        p)
            device_path="$OPTARG"
            ;;
        v)
            volume_label="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# Function to find the mount point of a device
find_mount_point() {
    local device_path="$1"
    local mount_point=""

    mount_point=$(findmnt -rno TARGET "$device_path" 2>/dev/null)
    if [ -z "$mount_point" ]; then
        echo "Error: Unable to find the mount point of: $device_path" >&2
        return 1
    fi

    echo "$mount_point"
    return 0
}

# Function to find the device path by volume label
find_device_by_label() {
    local volume_label="$1"
    local device_path=""

    device_path=$(findfs LABEL="$volume_label" 2>/dev/null)
    if [ -z "$device_path" ]; then
        echo "Error: Unable to find mounted volume: $volume_label" >&2
        return 1
    fi

    echo "$device_path"
    return 0
}

# Check if the destination path or volume label is provided
if [ -z "$destination_path" ] && [ -z "$volume_label" ]; then
    echo "Error: Please provide either a destination path or a volume label." >&2
    usage
    exit 1
fi

# Find the destination path
if [ -n "$device_path" ]; then
    destination_path=$(find_mount_point "$device_path")
    if [ $? -ne 0 ]; then
        exit 1
    fi
elif [ -n "$volume_label" ]; then
    device_path=$(find_device_by_label "$volume_label")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    destination_path=$(find_mount_point "$device_path")
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

echo "Target: $destination_path"

# Install rsync if not available
if ! command -v rsync &>/dev/null; then
    sudo apt-get update
    sudo apt-get install rsync -y
fi

# Copy the root directory to the destination
sudo rsync -axHAWX --numeric-ids --info=progress2 --exclude=/proc / "$destination_path"
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Error: Failed to copy the root directory to $destination_path" >&2
    exit $exit_code
fi

echo "Root directory copied successfully to $destination_path"