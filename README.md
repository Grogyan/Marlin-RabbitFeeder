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


