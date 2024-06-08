import socket
import subprocess
import threading

# Define the port to listen on
PORT = 5000
LOG_FILE = 'progress.log'

# Function to handle incoming connections
def handle_connection(client_socket):
    with open(LOG_FILE, 'r') as file:
        lines = file.readlines()
        if lines:
            client_socket.sendall(lines[-1].encode('utf-8'))
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

# Function to run tests and update the progress log
def run_tests():
    with open(LOG_FILE, 'w') as log_file:
        log_file.write("RUNNING\n")

    # First Test
    result = subprocess.run(['python3', 'systemreqtest.py'], capture_output=True)
    if result.returncode == 0:
        with open(LOG_FILE, 'w') as log_file:
            log_file.write("TESTED : System requirements test passed.\n")
    else:
        with open(LOG_FILE, 'w') as log_file:
            log_file.write("ERROR 1: System requirements test failed.\n")
        exit(1)

    # Second Test
    result = subprocess.run(['python3', 'testAllGpusResNet50.py'], capture_output=True)
    if result.returncode == 0:
        with open(LOG_FILE, 'w') as log_file:
            log_file.write("DONE\n")
    else:
        with open(LOG_FILE, 'w') as log_file:
            log_file.write("ERROR 2: Test All GPU ResNet50 failed.\n")
        exit(2)

# Run the tests
run_tests()

# Keep the script running to handle connections
server_thread.join()
