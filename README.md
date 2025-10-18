# Marlin-RabbitFeeder
Project to bridge an ERCF to Marlin Firmware Printers


Run Bash script via SSH
./setup_klipper_host_mcu.sh

This configures a Raspberry PI to run Klipper without a main board

In your Klipper printer.cfg
Set the primary [mcu] to use the dummy serial port from the host, and keep [mcu mmu] for your ERCF board (assuming it's flashed and connected as before):
Eg.
[mcu]
serial: /tmp/klipper_host_mcu  # Dummy serial for host MCU

[mcu mmu]
serial: /dev/serial/by-id/usb-Klipper_rp2040_E664B012CF438C2C-if00  # Your ERCF board


Further setup if needed
Step 1: Check Service Status and LogsRun these to diagnose:

sudo systemctl status klipper_mcu.service  # Check if running; look for errors like "failed" or "inactive"

If "Unit klipper_mcu.service not found," the service file might be missing or named incorrectly (e.g., try klipper-mcu.service with a hyphen if you recreated it).

tail -n 50 ~/klipper_logs/klippy.log  # Look for errors like "Permission denied" on /tmp/klipper_host_mcu or MCU connection failures

Common log error: "Unable to open port: [Errno 13] Permission denied: '/tmp/klipper_host_mcu'" → Fix in Step 3.

If the service isn't found, proceed to recreate it properly.Step 2: Rebuild and Reinstall Using Official Klipper MethodsKlipper's docs recommend using their pre-made service file and make flash for installation— this avoids manual errors.Stop services:

sudo service klipper stop
sudo systemctl stop klipper_mcu  # Or klipper-mcu if hyphenated

Navigate to Klipper dir: cd ~/klipper
Reconfigure and build:

make menuconfig  # Set Micro-controller Architecture: Linux process; save/exit
make clean
make
sudo make flash  # This installs to /usr/local/bin/klipper_mcu

If make flash fails (e.g., permission issues), run sudo setcap "cap_sys_nice=ep" out/klipper.elf first, then retry.

Install the official service file (overwrites any manual one):

sudo cp ./scripts/klipper-mcu.service /etc/systemd/system/klipper-mcu.service
sudo systemctl daemon-reload
sudo systemctl enable klipper-mcu.service
sudo systemctl start klipper-mcu.service

Note the hyphen in "klipper-mcu.service"—this matches Klipper's standard naming.

Restart Klipper: sudo service klipper start

Now check if /tmp/klipper_host_mcu exists: ls /tmp/klipper_host_mcu (should show it without errors). If not, revisit logs.Step 3: Fix Permissions (Common Fix for "Permission Denied")Add your user (e.g., "pi") to the tty group for socket access:

sudo usermod -a -G tty pi  # Replace "pi" with your username if different

Log out and back in (or reboot: sudo reboot) for changes to take effect.
If using GPIOs, ensure user is in gpio group: sudo usermod -a -G gpio pi

Step 4: Verify and TestRerun sudo systemctl status klipper-mcu.service—it should show "active (running)."
In your printer.cfg, ensure [mcu] points to /tmp/klipper_host_mcu.
Run FIRMWARE_RESTART in your Klipper console (via Mainsail/Fluidd).




