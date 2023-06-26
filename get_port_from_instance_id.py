import subprocess
import json
import sys

def get_host_port_from_instance_id(instance_id):
    cmd = ['./vast', 'show', 'instances', '--raw']
    result = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = result.communicate()

    if result.returncode != 0:
        print(f'Command failed with error code {result.returncode}')
        sys.exit(1)

    if not stdout:
        print(f'No output returned from command')
        sys.exit(1)

    try:
        data = json.loads(stdout.decode())
    except json.JSONDecodeError:
        print(f'Invalid JSON output: {stdout.decode()}')
        sys.exit(1)

    for instance in data:
        if instance['id'] == int(instance_id):
            if '5000/tcp' in instance['ports']:
                for port_map in instance['ports']['5000/tcp']:
                    print(port_map['HostPort'])
                    break
            else:
                print(f'No port 5000/tcp found for instance {instance_id}')
                sys.exit(2)


if __name__ == "__main__":
    instance_id = sys.argv[1]
    get_host_port_from_instance_id(instance_id)
