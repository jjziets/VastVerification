import ssl
import urllib.request
import sys

def fetch_progress(ip, port, debugging=False):
    url = f"https://{ip}:{port}/progress"
    try:
        if debugging:
            print(f"Attempting to connect to {url} with SSL context ignoring certificate verification.")
        
        # Create an SSL context that does not verify certificates
        context = ssl._create_unverified_context()
        response = urllib.request.urlopen(url, context=context)
        progress_data = response.read().decode('utf-8')
        
        if debugging:
            print(f"Successfully connected to {url}. Retrieved data:\n{progress_data}")
        
        return progress_data
    except Exception as e:
        error_message = f"ERROR: Failed to connect or retrieve data: {e}"
        
        if debugging:
            print(error_message)
        
        return error_message

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
    if not debugging:
        print(result)
