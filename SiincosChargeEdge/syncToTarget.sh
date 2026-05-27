#! /bin/zsh

#
# Sync project to target for building and testing
# Run from inside this project directory - this file location
#
# CLI Arguments:
# - 1. target ssh username
# - 2. target device hostname or IP address
# - 3. local project home folder (folder this file is located in)
# - 4. project home on target

TARGET_SSH_USERNAME=$1
TARGET_HOSTNAME=$2
PROJECT_HOME=$3
TARGET_PROJECT_HOME=$4
rsync -av --delete --progress --exclude '.git' --exclude '.build' $PROJECT_HOME $TARGET_SSH_USERNAME@$TARGET_HOSTNAME:$TARGET_PROJECT_HOME/..
