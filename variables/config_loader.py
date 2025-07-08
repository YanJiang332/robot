import yaml
import os

CONFIG_FILE = os.path.join(os.path.dirname(__file__), '..', 'config', 'devices.yml')

def get_config():
    """
    Loads the entire configuration from the devices.yml file.
    """
    if not os.path.exists(CONFIG_FILE):
        raise FileNotFoundError(f"Configuration file not found at: {CONFIG_FILE}")

    with open(CONFIG_FILE, 'r') as f:
        config = yaml.safe_load(f)

    return config

# Load the configuration once and expose it as variables
try:
    config_data = get_config()
    
    # Separate devices and passwords, and create FRR_DEVICES as a dictionary keyed by IP
    FRR_DEVICES = {}
    FRR_PASSWORDS_MAP = {}

    for device in config_data.get('devices', []):
        device_copy = device.copy() # Create a copy to modify
        ip = device_copy.get('ip')
        if ip: # Ensure IP exists before processing
            if 'password' in device_copy:
                FRR_PASSWORDS_MAP[ip] = device_copy.pop('password') # Remove password from device_copy and add to map
            FRR_DEVICES[ip] = device_copy # Add device to FRR_DEVICES dictionary
    GLOBAL_COMMANDS = config_data.get('global_commands', [])
except Exception as e:
    print(f"Error loading config: {e}")
    FRR_DEVICES = []
    FRR_PASSWORDS_MAP = {} # Initialize even on error
    GLOBAL_COMMANDS = []