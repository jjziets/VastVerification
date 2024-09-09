import requests
import time
from datetime import datetime
import argparse
import subprocess
import sys

try:
    import dns.resolver
except ImportError:
    print("The 'dnspython' library is required for DNS resolution.")
    print("Install it using: pip install dnspython")
    sys.exit(1)

# Function to parse command-line arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description="API monitoring script with timeout handling.")
    
    parser.add_argument(
        '-k', '--api_key', 
        type=str, 
        required=True, 
        help="API key to use for requests."
    )
    parser.add_argument(
        '-d', '--delay', 
        type=float, 
        default=1.0, 
        help="Delay between requests in seconds (default: 1 second)."
    )
    parser.add_argument(
        '-t', '--timeout_threshold',
        type=int,
        default=5,
        help="Timeout threshold in seconds (default: 5 seconds)."
    )
    parser.add_argument(
        '--no-ping',
        action='store_true',
        help="Disable ping test on timeout."
    )
    parser.add_argument(
        '--no-dns',
        action='store_true',
        help="Disable DNS test on timeout."
    )
    
    return parser.parse_args()

# Function to ping 1.1.1.1
def ping_test():
    try:
        response = subprocess.run(
            ["ping", "-c", "1", "1.1.1.1"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if response.returncode == 0:
            return f"Ping successful:\n{response.stdout.strip()}"
        else:
            return f"Ping failed:\n{response.stderr.strip()}"
    except Exception as e:
        return f"Ping command failed: {e}"

# Function to perform DNS resolution
def dns_test():
    resolver = dns.resolver.Resolver()
    resolver.nameservers = ['1.1.1.1']
    try:
        answers = resolver.resolve('console.vast.ai', 'A')
        ips = [answer.to_text() for answer in answers]
        return f"DNS resolution successful: console.vast.ai -> {', '.join(ips)}"
    except dns.resolver.NXDOMAIN:
        return "DNS resolution failed: Domain does not exist."
    except dns.resolver.Timeout:
        return "DNS resolution failed: Request timed out."
    except dns.resolver.NoAnswer:
        return "DNS resolution failed: No answer received."
    except Exception as e:
        return f"DNS resolution failed: {e}"

# Main function to run the script
def main():
    args = parse_arguments()

    # API URL
    api_url = f"https://console.vast.ai/api/v0/instances?owner=me&api_key={args.api_key}"

    # Timeout threshold in seconds
    timeout_threshold = args.timeout_threshold
    start_timeout = None

    # Counters for success and failures
    success_count = 0
    failure_count = 0

    # Record the start time
    start_time = datetime.now()

    # Print initial time and date
    print(f"Start Time: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Monitoring API: {api_url}")
    print(f"Request delay: {args.delay} seconds")
    print(f"Timeout threshold: {timeout_threshold} seconds")
    print("Press Ctrl+C to stop...\n")

    try:
        while True:
            try:
                response = requests.get(api_url, timeout=timeout_threshold)
                response.raise_for_status()

                # Print a dot for successful API call
                print('.', end='', flush=True)
                success_count += 1

                # Reset timeout flag if it was set
                if start_timeout:
                    downtime = time.time() - start_timeout
                    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Connection restored after {downtime:.2f} seconds of timeout.")
                    start_timeout = None

            except requests.exceptions.Timeout:
                failure_count += 1
                if not start_timeout:
                    start_timeout = time.time()
                    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Request timed out.")

                    # Perform DNS test
                    if not args.no_dns:
                        dns_result = dns_test()
                        print(f"DNS Test Result: {dns_result}")

                    # Perform ping test
                    if not args.no_ping:
                        ping_result = ping_test()
                        print(f"Ping Test Result:\n{ping_result}")

            except requests.exceptions.RequestException as e:
                failure_count += 1
                print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] An error occurred: {e}")

            time.sleep(args.delay)

    except KeyboardInterrupt:
        # Calculate the duration of the testing
        end_time = datetime.now()
        duration = end_time - start_time

        # Print the summary
        print("\n\n--- Testing Summary ---")
        print(f"Start Time: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"End Time: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Duration: {duration}")
        print(f"Total Requests Sent: {success_count + failure_count}")
        print(f" - Successful Requests: {success_count}")
        print(f" - Failed Requests: {failure_count}")
        print("-----------------------")

if __name__ == "__main__":
    main()
