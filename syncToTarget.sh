#! /bin/zsh

#
# Sync project to target for building and testing
# Run from inside this project directory - this file location
#
# CLI Arguments:
# - 1. target ssh username
# - 2. target device hostname or IP address
#

TARGET_SSH_USERNAME=$1
TARGET_HOSTNAME=$2
rsync -av --delete --progress --exclude '.git' --exclude '.build' ../SiincosCharge $TARGET_SSH_USERNAME@$TARGET_HOSTNAME:/opt/
