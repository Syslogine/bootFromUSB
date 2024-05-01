#!/bin/bash
#
# Script to retrieve the PARTUUID (Partition UUID) of a specified disk partition
#
# Copyright (c) 2016-2024 Jetsonhacks
# MIT License

# Set the default partition target
partition_target="/dev/sda1"

# Function to display usage information
usage() {
    echo "Usage: $0 [-p partition] [-h]"
    echo "  -p, --partition  Specify the partition (default: /dev/sda1)"
    echo "  -h, --help       Display this help message"
}

# Parse command-line arguments using getopts
while getopts ":p:h" opt; do
    case $opt in
        p)
            partition_target="$OPTARG"
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

# Check if the specified partition exists
if ! blkid -p "$partition_target" >/dev/null 2>&1; then
    echo "Error: Partition $partition_target not found" >&2
    exit 1
fi

# Get the PARTUUID of the specified partition
partuuid_string=$(blkid -o value -s PARTUUID "$partition_target")

# Print the PARTUUID and a sample extlinux.conf snippet
echo "PARTUUID of Partition: $partition_target"
echo "$partuuid_string"
echo
echo "Sample snippet for /boot/extlinux/extlinux.conf entry:"
echo 'APPEND ${cbootargs} root=PARTUUID='"$partuuid_string"' rootwait rootfstype=ext4'