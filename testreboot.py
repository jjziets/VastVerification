import requests

# API key and instance ID
api_key = ''
instance_id = '12162570'

# API endpoint
url = f'https://console.vast.ai/api/v0/instances/reboot/{instance_id}/?api_key={api_key}'

try:
    # Sending PUT request to the API
    response = requests.put(url)
    
    # Check if the request was successful
    if response.status_code == 200:
        print(f"Rebooting instance {instance_id}.")
    else:
        print(f"Failed to reboot instance {instance_id}. Status code: {response.status_code}")
        print(f"Response: {response.text}")

except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}")
