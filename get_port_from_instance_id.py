import subprocess
import json
import sys
import time

def get_host_port_from_instance_id(instance_id, attempts=5, initial_delay=1):
    cmd = ['./vast', 'show', 'instances', '--raw']

    for attempt in range(attempts):
        result = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = result.communicate()

        if result.returncode != 0:
            print(f'Command failed with error code {result.returncode}')
            sys.exit(1)

        if not stdout:
            print(f'No output returned from command. Waiting {initial_delay * 2**attempt} seconds before retrying...')
            time.sleep(initial_delay * 2**attempt)
            continue

        try:
            data = json.loads(stdout.decode())
        except json.JSONDecodeError as e:
            if 'error 429' in str(e) or 'invalid structure' in str(e):
                print(f'Received error or invalid structure, waiting {initial_delay * 2**attempt} seconds before retrying...')
                time.sleep(initial_delay * 2**attempt)
                continue
            else:
                print(f'Invalid JSON output: {stdout.decode()}')
                sys.exit(1)

        for instance in data:
            if instance['id'] == int(instance_id):
                if 'ports' in instance and '5000/tcp' in instance['ports']:
                    #print(f'Host port for instance {instance_id} on 5000/tcp: {instance["ports"]["5000/tcp"][0]["HostPort"]}')
                    print(f'{instance["ports"]["5000/tcp"][0]["HostPort"]}')
                    return
                else:
                    print(f'No port 5000/tcp found for instance {instance_id}')
                    sys.exit(2)

    print(f'Failed to get port after {attempts} attempts.')
    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print('Please provide an instance ID as a command line argument.')
        sys.exit(1)
    instance_id = sys.argv[1]
    get_host_port_from_instance_id(instance_id)
