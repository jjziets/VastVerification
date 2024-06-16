import ssl
import urllib.request
import sys

def fetch_progress(ip, port):
    url = f"https://{ip}:{port}/progress"
    try:
        # Create an SSL context that does not verify certificates
        context = ssl._create_unverified_context()
        response = urllib.request.urlopen(url, context=context)
        return response.read().decode('utf-8')
    except Exception as e:
        return f"Failed to connect or retrieve data: {e}"

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 https_client.py <IP> <PORT>")
        sys.exit(1)

    ip = sys.argv[1]
    port = sys.argv[2]
    print("Server response:")
    print(fetch_progress(ip, port))
