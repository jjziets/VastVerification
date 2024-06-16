import socket
import subprocess
import threading
import psutil

# Define the port to listen on
PORT = 5000
LOG_FILE = 'progress.log'

# Function to handle incoming connections
def handle_connection(client_socket):
    with open(LOG_FILE, 'r') as file:
        lines = file.readlines()
        if lines:
            client_socket.sendall(''.join(lines).encode('utf-8'))
        else:
            client_socket.sendall('No progress logged yet.\n'.encode('utf-8'))
    client_socket.close()

# Function to start the server
def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind(('0.0.0.0', PORT))
    server_socket.listen(5)
    print(f"Listening on port {PORT}...")

    while True:
        client_socket, addr = server_socket.accept()
        print(f"Accepted connection from {addr}")
        client_handler = threading.Thread(target=handle_connection, args=(client_socket,))
        client_handler.start()

# Start the server in a separate thread
server_thread = threading.Thread(target=start_server)
server_thread.start()

# Function to log messages to progress.log and print to stdout
def log_message(message):
    with open(LOG_FILE, 'a') as log_file:
        log_file.write(message + '\n')
    print(message)

# Function to log messages to progress.log and print to stdout
def write_message(message):
    with open(LOG_FILE, 'w') as log_file:
        log_file.write(message + '\n')
    print(message)


# Function to run tests and update the progress log
def run_tests():
    # Clear the log file at the start
    with open(LOG_FILE, 'w') as log_file:
        log_file.write("")  # Empty the log file

    log_message("Starting tests...")

    # First Test
    log_message("Running system requirements test...")
    result = subprocess.run(['python3', 'systemreqtest.py'], capture_output=True, text=True)
    if result.returncode == 0:
        log_message("TESTED : System requirements test passed.")
    else:
        write_message("ERROR 1: System requirements test failed. " + result.stdout + " " + result.stderr)
        return  # Exit without logging "DONE"

    # Second Test
    log_message("Running ResNet50 test on all GPUs...")
    result = subprocess.run(['python3', 'testAllGpusResNet50.py'], capture_output=True, text=True)
    if result.returncode == 0:
        log_message("TESTED : ResNet50 passed")
    else:
        write_message("ERROR 2: Test All GPU ResNet50 failed. " + result.stdout + " " + result.stderr)
        return  # Exit without logging "DONE"

    # Third Test - Run stress-ng and gpu-burn simultaneously
    log_message("Running stress-ng and gpu-burn tests simultaneously for 60 seconds...")
    cpu_cores = psutil.cpu_count(logical=True) - 1  # Use all CPU cores except one
    stress_ng_command = ['stress-ng', '--cpu', str(cpu_cores), '--timeout', '60s']
    gpu_burn_command = ['./gpu_burn', '60']

    try:
        # Start both stress-ng and gpu-burn simultaneously
        stress_ng_process = subprocess.Popen(stress_ng_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        gpu_burn_process = subprocess.Popen(gpu_burn_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Wait for both processes to complete
        stress_ng_stdout, stress_ng_stderr = stress_ng_process.communicate()
        gpu_burn_stdout, gpu_burn_stderr = gpu_burn_process.communicate()

        # Check if both processes completed successfully
        if stress_ng_process.returncode == 0 and gpu_burn_process.returncode == 0:
             write_message("DONE")
        else:
            if stress_ng_process.returncode != 0:
                write_message("ERROR 3: stress-ng test failed. " + stress_ng_stdout.decode() + " " + stress_ng_stderr.decode())
            if gpu_burn_process.returncode != 0:
                write_message("ERROR 4: gpu-burn test failed. " + gpu_burn_stdout.decode() + " " + gpu_burn_stderr.decode())
    except Exception as e:
        write_message(f"ERROR 5: An exception occurred while running the tests: {str(e)}")

# Run the tests
run_tests()

# Keep the script running to handle connections
server_thread.join()
