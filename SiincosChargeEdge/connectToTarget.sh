#! /bin/zsh

#
# Open macOS Terminal and connect to target
# Run from inside this project directory - this file location
#
# CLI Arguments:
# - 1. target ssh username
# - 2. target device hostname or IP address
#

TARGET_SSH_USERNAME="$1"
TARGET_HOSTNAME="$2"

osascript - "$TARGET_SSH_USERNAME" "$TARGET_HOSTNAME" <<'EOF'
on run argv
    set targetUser to item 1 of argv
    set targetHost to item 2 of argv

    tell application "Terminal"
        activate
        set newWindow to do script "ssh -t " & targetUser & "@" & targetHost & " 'cd /opt/SiincosCharge; bash -l'"
        -- Set window size (width x height in characters)
        set number of columns of front window to 180
        set number of rows of front window to 60
    end tell
end run
EOF
