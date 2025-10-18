#!/bin/bash

# This script has been created by Grok AI, and as such may contain errors.
# Updated Bash script to set up Klipper host MCU on Raspberry Pi and ensure the serial port (/tmp/klipper_host_mcu) is active at boot.
# This automates building the firmware for Linux process, installing the systemd service, and enabling it.
# Assumptions: Klipper is cloned to ~/klipper, and you're running as the pi user (or adjust USERNAME).
# Run this script with sudo where needed, or as root. If menuconfig needs interaction, run it manually first.
# Updates: Corrected .config settings for Linux process MCU to avoid AVR/STM32 build errors like "specify FLASH_DEVICE".
#          Uses absolute paths for copying service file, adds check for file existence, and improved error handling.

set -e  # Exit on error

KLIPPER_DIR="$HOME/klipper"
USERNAME="pi"  # Change if your user is different

# Step 1: Check if Klipper directory exists
if [ ! -d "$KLIPPER_DIR" ]; then
    echo "Error: Klipper directory $KLIPPER_DIR not found. Clone it first: git clone https://github.com/Klipper3d/klipper $KLIPPER_DIR"
    exit 1
fi

# Step 2: Navigate to Klipper directory
cd "$KLIPPER_DIR"

# Step 3: Configure and build firmware non-interactively (set defaults for Linux process)
# Note: This creates .config if not present; for custom changes, run 'make menuconfig' manually first.
echo "Configuring for Linux process MCU..."
cat << EOF > .config
CONFIG_LINUX_PROCESS=y
CONFIG_BOARD_DIRECTORY="linux"
CONFIG_CLOCK_FREQ=1000000
CONFIG_SERIAL_BAUD=250000
CONFIG_INITIAL_PINS=""
CONFIG_HAVE_GPIO=y
CONFIG_INLINE_STEPPER_HACK=y
EOF
make olddefconfig  # Apply defaults to config

# Build the firmware
echo "Building Klipper host MCU firmware..."
make clean
make

# Step 4: Install (flash) the built firmware
echo "Stopping Klipper service..."
sudo service klipper stop
echo "Flashing firmware..."
sudo make flash
echo "Starting Klipper service..."
sudo service klipper start

# Step 5: Install and enable the systemd service for auto-start at boot
SERVICE_FILE="${KLIPPER_DIR}/scripts/klipper-mcu.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: Service file $SERVICE_FILE not found. Update Klipper repo: git pull"
    exit 1
fi

echo "Installing klipper-mcu.service..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/klipper-mcu.service
sudo systemctl daemon-reload
sudo systemctl enable klipper-mcu.service
sudo systemctl start klipper-mcu.service

# Step 6: Fix permissions for serial access (common issue)
echo "Adding user to tty group for /tmp/klipper_host_mcu access..."
sudo usermod -a -G tty "$USERNAME"

# Step 7: Verify
echo "Verifying setup..."
if [ -e /tmp/klipper_host_mcu ]; then
    echo "Success: Serial port /tmp/klipper_host_mcu is active."
else
    echo "Warning: Serial port not found. Reboot and check klippy.log for errors."
fi

echo "Setup complete. Reboot the Pi for changes to take full effect: sudo reboot"
echo "After reboot, check with: sudo systemctl status klipper-mcu.service"
