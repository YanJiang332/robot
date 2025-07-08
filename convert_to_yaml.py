import yaml
import os

# Define file paths
CONFIG_DIR = 'config'
DEVICES_TXT = os.path.join(CONFIG_DIR, 'devices.txt')
COMMANDS_TXT = os.path.join(CONFIG_DIR, 'commands.txt')
DEVICES_YAML = os.path.join(CONFIG_DIR, 'devices.yml')

# Default credentials and commands
import os
DEFAULT_USERNAME = os.getenv('FRR_USERNAME', 'admin')
DEFAULT_PASSWORD = os.getenv('FRR_PASSWORD', 'Admin@123')

def read_file_lines(path):
    """Reads lines from a file, ignoring empty lines and comments."""
    if not os.path.exists(path):
        return []
    with open(path, 'r') as f:
        return [line.strip() for line in f if line.strip() and not line.startswith('#')]

def main():
    """
    Reads devices and commands from .txt files and generates a structured devices.yml file.
    If devices.yml already exists, it merges the new devices from .txt.
    """
    # Read devices and commands from .txt files
    devices_from_txt = read_file_lines(DEVICES_TXT)
    commands_from_txt = read_file_lines(COMMANDS_TXT)

    if not devices_from_txt:
        print("No devices found in devices.txt. Nothing to do.")
        return

    # Load existing YAML file if it exists
    existing_devices = {}
    if os.path.exists(DEVICES_YAML):
        with open(DEVICES_YAML, 'r') as f:
            data = yaml.safe_load(f)
            if data and 'devices' in data:
                for device in data['devices']:
                    existing_devices[device['ip']] = device

    # Merge devices from .txt into the data from .yml
    for ip in devices_from_txt:
        if ip not in existing_devices:
            print(f"Adding new device from .txt: {ip}")
            existing_devices[ip] = {
                'ip': ip,
                'username': DEFAULT_USERNAME,
                'password': DEFAULT_PASSWORD
            }

    # Prepare the final data structure for YAML
    output_data = {
        'global_commands': commands_from_txt,
        'devices': list(existing_devices.values())
    }

    # Write the data to the YAML file
    with open(DEVICES_YAML, 'w') as f:
        yaml.dump(output_data, f, default_flow_style=False, sort_keys=False)

    print(f"\nSuccessfully generated/updated '{DEVICES_YAML}'")
    print(f" - Found {len(commands_from_txt)} global commands.")
    print(f" - Total devices in file: {len(existing_devices)}")

if __name__ == '__main__':
    main()
