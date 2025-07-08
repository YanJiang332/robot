import paramiko
import concurrent.futures
import os
import logging
import time

# Configure logging for the library
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(threadName)s - %(levelname)s - %(message)s')

class ConcurrentSSH:

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def _execute_single_device_commands(self, device_info, password, commands, collection_dir):
        """
        Connects to a single device, executes commands, and saves output.
        Returns a tuple: (ip, status, message)
        """
        ip = device_info['ip']
        username = device_info['username']
        client = None
        result_status = "FAIL"
        result_message = ""
        all_outputs = []

        self.logger.info(f"Attempting to connect to {ip}")
        try:
            client = paramiko.SSHClient()
            client.load_system_host_keys()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # Connect with a timeout
            client.connect(hostname=ip, username=username, password=password, timeout=10)
            self.logger.info(f"Successfully connected to {ip}")

            for cmd in commands:
                self.logger.info(f"Executing command on {ip}: {cmd}")
                stdin, stdout, stderr = client.exec_command(cmd, timeout=10)
                output = stdout.read().decode('utf-8').strip()
                error = stderr.read().decode('utf-8').strip()

                header = f"--- Command: {cmd} ---"
                if error:
                    self.logger.warning(f"Command '{cmd}' on {ip} returned error: {error}")
                    all_outputs.append(f"{header}\n!!! ERROR: {error} !!!\n{output}")
                else:
                    all_outputs.append(f"{header}\n{output}")
            
            # Save collected config to file
            output_file_path = os.path.join(collection_dir, f"frr_config_{ip}.txt")
            os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
            with open(output_file_path, 'w') as f:
                f.write("\n\n".join(all_outputs))
            self.logger.info(f"All command outputs for {ip} saved to: {output_file_path}")

            result_status = "PASS"
            result_message = "Collection successful"

        except paramiko.AuthenticationException:
            result_message = "Authentication failed"
            self.logger.error(f"Authentication failed for {ip}")
        except paramiko.SSHException as e:
            result_message = f"SSH error: {e}"
            self.logger.error(f"SSH error on {ip}: {e}")
        except TimeoutError:
            result_message = "Connection or command timed out"
            self.logger.error(f"Timeout on {ip}")
        except Exception as e:
            result_message = f"An unexpected error occurred: {e}"
            self.logger.error(f"Unexpected error on {ip}: {e}")
        finally:
            if client:
                client.close()
                self.logger.info(f"Connection to {ip} closed.")
        
        return ip, result_status, result_message

    def run_concurrent_collection(self, devices_list, passwords_map, commands_list, base_collection_dir, max_workers=5):
        """
        Runs SSH command collection concurrently on multiple devices.
        
        :param devices_list: List of device dictionaries (without passwords).
        :param passwords_map: Dictionary mapping IP to password.
        :param commands_list: List of commands to execute on each device.
        :param base_collection_dir: Base directory to save collected configs.
        :param max_workers: Maximum number of concurrent threads.
        :return: A dictionary summarizing results for each device.
        """
        self.logger.info(f"Starting concurrent collection on {len(devices_list)} devices with {max_workers} workers.")
        
        results = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_ip = {
                executor.submit(
                    self._execute_single_device_commands, 
                    device, 
                    passwords_map.get(device['ip']), 
                    commands_list, 
                    base_collection_dir
                ): device['ip'] 
                for device in devices_list
            }
            
            for future in concurrent.futures.as_completed(future_to_ip):
                ip = future_to_ip[future]
                try:
                    device_ip, status, message = future.result()
                    results[device_ip] = {"status": status, "message": message}
                    self.logger.info(f"Result for {device_ip}: {status} - {message}")
                except Exception as exc:
                    self.logger.error(f"{ip} generated an exception: {exc}")
                    results[ip] = {"status": "FAIL", "message": f"Exception during processing: {exc}"}
        
        self.logger.info("Concurrent collection complete.")
        return results

    def _run_single_device_check_commands(self, device_info, password, commands_to_run):
        """
        Connects to a single device, executes a map of commands, and returns their outputs.
        Returns a tuple: (ip, status, message, command_outputs_map)
        """
        ip = device_info['ip']
        username = device_info['username']
        client = None
        result_status = "FAIL"
        result_message = ""
        command_outputs_map = {}

        self.logger.info(f"Attempting to connect to {ip} for checks")
        try:
            client = paramiko.SSHClient()
            client.load_system_host_keys()
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            client.connect(hostname=ip, username=username, password=password, timeout=10)
            self.logger.info(f"Successfully connected to {ip} for checks")

            for cmd_name, cmd_string in commands_to_run.items():
                self.logger.info(f"Executing check command on {ip}: {cmd_string}")
                stdin, stdout, stderr = client.exec_command(cmd_string, timeout=10)
                output = stdout.read().decode('utf-8').strip()
                error = stderr.read().decode('utf-8').strip()
                
                if error:
                    self.logger.warning(f"Check command '{cmd_string}' on {ip} returned error: {error}")
                    command_outputs_map[cmd_name] = {"output": output, "error": error, "status": "ERROR"}
                else:
                    command_outputs_map[cmd_name] = {"output": output, "error": "", "status": "SUCCESS"}
            
            result_status = "PASS"
            result_message = "All checks commands executed"

        except paramiko.AuthenticationException:
            result_message = "Authentication failed"
            self.logger.error(f"Authentication failed for {ip} during checks")
        except paramiko.SSHException as e:
            result_message = f"SSH error during checks: {e}"
            self.logger.error(f"SSH error on {ip} during checks: {e}")
        except TimeoutError:
            result_message = "Connection or command timed out during checks"
            self.logger.error(f"Timeout on {ip} during checks")
        except Exception as e:
            result_message = f"An unexpected error occurred during checks: {e}"
            self.logger.error(f"Unexpected error on {ip} during checks: {e}")
        finally:
            if client:
                client.close()
                self.logger.info(f"Connection to {ip} closed after checks.")
        
        return ip, result_status, result_message, command_outputs_map

    def run_concurrent_checks(self, devices_list, passwords_map, commands_map_per_device, max_workers=5):
        """
        Runs SSH check commands concurrently on multiple devices.
        
        :param devices_list: List of device dictionaries (without passwords).
        :param passwords_map: Dictionary mapping IP to password.
        :param commands_map_per_device: A dictionary where keys are device IPs and values are
                                        dictionaries of commands to run on that device (e.g., {'cmd_name': 'cmd_string'}).
        :param max_workers: Maximum number of concurrent threads.
        :return: A dictionary summarizing results for each device, including command outputs.
                 Example: {'ip': {'status': 'PASS/FAIL', 'message': '...', 'command_outputs': {'cmd_name': {'output': '...', 'error': '...'}}}}
        """
        self.logger.info(f"Starting concurrent checks on {len(devices_list)} devices with {max_workers} workers.")
        
        results = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_ip = {}
            for device in devices_list:
                ip = device['ip']
                if ip in commands_map_per_device:
                    future = executor.submit(
                        self._run_single_device_check_commands, 
                        device, 
                        passwords_map.get(ip), 
                        commands_map_per_device[ip]
                    )
                    future_to_ip[future] = ip
                else:
                    self.logger.warning(f"No commands specified for device {ip}. Skipping.")
                    results[ip] = {"status": "SKIPPED", "message": "No commands specified for checks."}
            
            for future in concurrent.futures.as_completed(future_to_ip):
                ip = future_to_ip[future]
                try:
                    device_ip, status, message, command_outputs = future.result()
                    results[device_ip] = {"status": status, "message": message, "command_outputs": command_outputs}
                    self.logger.info(f"Result for {device_ip}: {status} - {message}")
                except Exception as exc:
                    self.logger.error(f"{ip} generated an exception: {exc}")
                    results[ip] = {"status": "FAIL", "message": f"Exception during processing: {exc}", "command_outputs": {}}
        
        self.logger.info("Concurrent checks complete.")
        return results
