import os
import subprocess
import ssl
import http.server
import threading
import psutil

# We import torch here so we can dynamically detect the number of GPUs.
# If PyTorch is not installed, this import will fail.
import torch

# Define the port to listen on and the log file to serve
PORT = 5000
LOG_FILE = 'progress.log'
CERT_FILE = 'server.crt'
KEY_FILE = 'server.key'

def generate_self_signed_cert():
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("Generating self-signed certificate and private key...")
        try:
            subprocess.run([
                'openssl', 'req', '-new', '-newkey', 'rsa:2048', '-days', '365', '-nodes', '-x509',
                '-subj', '/CN=localhost',
                '-keyout', KEY_FILE, '-out', CERT_FILE
            ], check=True)
            print("Certificate and key generated successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to generate certificate and key: {e}")
            exit(1)

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/progress':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            if os.path.exists(LOG_FILE):
                with open(LOG_FILE, 'r') as file:
                    self.wfile.write(file.read().encode('utf-8'))
            else:
                self.wfile.write(b"No progress logged yet.\n")
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 Not Found")

generate_self_signed_cert()

def start_https_server():
    httpd = http.server.HTTPServer(('0.0.0.0', PORT), CustomHTTPRequestHandler)
    httpd.socket = ssl.wrap_socket(httpd.socket,
                                   keyfile=KEY_FILE,
                                   certfile=CERT_FILE,
                                   server_side=True)
    print(f"Serving HTTPS on port {PORT}...")
    httpd.serve_forever()

server_thread = threading.Thread(target=start_https_server)
server_thread.start()

def log_message(message):
    with open(LOG_FILE, 'a') as log_file:
        log_file.write(message + '\n')
    print(message, flush=True)

def write_message(message):
    with open(LOG_FILE, 'w') as log_file:
        log_file.write(message + '\n')
    print(message, flush=True)

def run_tests():
    # Clear the log file at the start
    with open(LOG_FILE, 'w') as log_file:
        log_file.write("")

    log_message("Starting tests...")

    # First Test
    log_message("Running system requirements test...")
    result = subprocess.run(['python3', 'systemreqtest.py'], capture_output=True, text=True)
    print(result.stdout, flush=True)
    print(result.stderr, flush=True)
    if result.returncode == 0:
        log_message("TESTED : System requirements test passed.")
    else:
        write_message("ERROR 1: System requirements test failed. " + result.stdout + " " + result.stderr)
        return

    # Second Test
    log_message("Running ResNet50 test on all GPUs...")
    result = subprocess.run(['python3', 'testAllGpusResNet50.py'], capture_output=True, text=True)
    print(result.stdout, flush=True)
    print(result.stderr, flush=True)
    if result.returncode == 0:
        log_message("TESTED : ResNet50 passed")
    else:
        write_message("ERROR 2: Test All GPU ResNet50 failed. " + result.stdout + " " + result.stderr)
        return

    # Third Test
    log_message("Running ECC test on all GPUs...")
    result = subprocess.run(['python3', 'eccfunction.py'], capture_output=True, text=True)
    print(result.stdout, flush=True)
    print(result.stderr, flush=True)
    if result.returncode == 0:
        log_message("TESTED : ECC test passed.")
    else:
        write_message("ERROR 3: ECC test failed. " + result.stdout + " " + result.stderr)
        return

    # Fourth Test: NCCL distributed test (dynamic GPU detection)
    try:
        gpu_count = torch.cuda.device_count()
    except Exception as e:
        write_message("ERROR 4: Unable to detect GPU count using PyTorch. " + str(e))
        return

    if gpu_count == 0:
        write_message("ERROR 4: No GPUs detected. Cannot run NCCL test.")
        return

    log_message(f"Running NCCL distributed test with {gpu_count} GPUs...")
    result = subprocess.run(
        [
            'python3',
            'test_NCCL.py',
            '--backend', 'NCCL',
            '--num-gpus', str(gpu_count),   # pass the dynamically detected GPU count
            '--num-machines', '1',
            '--machine-rank', '0'
            # The --dist-url defaults to tcp://127.0.0.1:1234 in test_NCCL.py
        ],
        capture_output=True,
        text=True
    )
    print(result.stdout, flush=True)
    print(result.stderr, flush=True)
    if result.returncode == 0:
        log_message("TESTED : NCCL distributed test passed.")
    else:
        write_message("ERROR 4: NCCL distributed test failed. " + result.stdout + " " + result.stderr)
        return

    # Fifth Test - Run stress-ng and gpu-burn simultaneously
    log_message("Running stress-ng and gpu-burn tests simultaneously for 60 seconds...")
    cpu_cores = psutil.cpu_count(logical=True) - 1  # Use all CPU cores except one
    stress_ng_command = ['stress-ng', '--cpu', str(cpu_cores), '--timeout', '60s']
    gpu_burn_command = ['./gpu_burn', '60']

    try:
        stress_ng_process = subprocess.Popen(stress_ng_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        gpu_burn_process = subprocess.Popen(gpu_burn_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        stress_ng_stdout, stress_ng_stderr = stress_ng_process.communicate()
        gpu_burn_stdout, gpu_burn_stderr = gpu_burn_process.communicate()

        if stress_ng_process.returncode == 0 and gpu_burn_process.returncode == 0:
            write_message("DONE")
        else:
            if stress_ng_process.returncode != 0:
                write_message("ERROR 5: stress-ng test failed. " + stress_ng_stdout.decode() + " " + stress_ng_stderr.decode())
            if gpu_burn_process.returncode != 0:
                write_message("ERROR 6: gpu-burn test failed. " + gpu_burn_stdout.decode() + " " + gpu_burn_stderr.decode())
    except Exception as e:
        write_message(f"ERROR 7: An exception occurred while running the tests: {str(e)}")

# Run the tests
run_tests()

# Keep the script running to handle connections
server_thread.join()
