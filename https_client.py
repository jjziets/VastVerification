import ssl
import urllib.request
import sys
import time

def fetch_progress(ip, port, debugging=False, retries=3, retry_interval=30):
    url = f"https://{ip}:{port}/progress"
    attempt = 0

    while attempt < retries:
        try:
            if debugging:
                print(f"Attempting to connect to {url} with SSL context ignoring certificate verification. Attempt {attempt + 1}/{retries}")

            # Create an SSL context that does not verify certificates
            context = ssl._create_unverified_context()
            response = urllib.request.urlopen(url, context=context)
            progress_data = response.read().decode('utf-8')

            if debugging:
                print(f"Successfully connected to {url}. Retrieved data:\n{progress_data}")

            return progress_data

        except Exception as e:
            # Check if we've exhausted all retries
            if attempt + 1 == retries:
                # Print or return the error message only after the final attempt
                error_message = f"ERROR: Failed to connect or retrieve data: {e}"
                return error_message

            if debugging:
                print(f"Attempt {attempt + 1} failed. Retrying in {retry_interval} seconds...")

            # Wait before retrying
            time.sleep(retry_interval)

            # Increment the attempt count
            attempt += 1

if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python3 https_client.py <IP> <PORT> [--debugging]")
        sys.exit(1)

    ip = sys.argv[1]
    port = sys.argv[2]
    debugging = len(sys.argv) == 4 and sys.argv[3] == "--debugging"

    if debugging:
        print("Debugging mode enabled.")
        print(f"IP: {ip}, PORT: {port}")

    result = fetch_progress(ip, port, debugging)
    print(result)
