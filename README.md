# Automated Machine Testing for Vast.ai Marketplace

## Overview

This project is designed to automate the testing of unverified machines available on the Vast.ai marketplace. The goal is to curate a list of machines that meet specific minimum requirements, ensuring they are suitable for further testing and potential verification by the Vast.ai developers.

The project includes scripts and a Docker image that collectively:
- Identify unverified machines.
- Validate if they meet specific technical requirements.
- Run a series of tests to ensure their network setup and performance capabilities.
- Report the results to assist in the verification process.

## Minimum Requirements for Machines

To qualify for detailed testing, a machine must:
- Be available and not currently occupied.
- Meet the following criteria, verified through the `./vast search offers` command:
  ```bash
  cuda_vers>=12.4 verified=any reliability>0.90 direct_port_count>3 pcie_bw>3 inet_down>10 inet_up>10 gpu_ram>7
  ```
- Presence of GPUs: The system must have one or more GPUs.
- Consistency of GPU Models: All GPUs in the system should be of the same model.
- VRAM Utilization: Each GPU should have at least 98% of its VRAM free.
- System RAM vs. VRAM: The total system RAM must be at least as large as the combined VRAM of all GPUs.
- CPU Cores: There should be at least 2 CPU cores available for each GPU in the system.
- Evaluate the GPU performance of a system by running benchmarks on the ResNet-18 model
- Simultaneously runs stress-ng to stress test the CPU and gpu_burn to stress test the GPU for 180 seconds.
- Ensures that the machine can handle high loads on both CPU and GPU concurrently without crashing or significant performance degradation.
- The docker image must be loaded in 2000s(33min) and the docker image should complete testing in 300s(5min)


## Step-by-Step Guide: Using `./autoverify_machineid.sh`

### Overview

The `autoverify_machineid.sh` script is part of a suite of tools designed to automate the testing of machines on the Vast.ai marketplace. This script specifically tests a single machine to determine if it meets the minimum requirements necessary for further verification.

### Prerequisites

Before you start using `./autoverify_machineid.sh`, ensure you have the following:

1. **Vast.ai Command Line Interface (vastcli)**: This tool is used to interact with the Vast.ai platform.
2. **Docker**: Docker should be installed and configured on the target machines.

### Setup and Installation

1. **Download and Setup `vastcli`**:
   - Download the Vast.ai CLI tool using the following command:
     ```bash
     wget https://raw.githubusercontent.com/vast-ai/vast-python/master/vast.py -O vast
     chmod +x vast
     ```

   - Set your Vast.ai API key:
     ```bash
     ./vast set api-key 6189d1be9f15ad2dced0ac4e3dfd1f648aeb484d592e8ad13aaf50aeedd24c07
     ```

2. **Clone the Repository**:
   - Clone the project repository to your local machine:
     ```bash
     git clone <repository-url>
     cd <repository-directory>
     ```

3. **Make Scripts Executable**:
   - Change the permissions of the main scripts to make them executable:
     ```bash
     chmod +x autoverify.sh
     chmod +x autoverify_machineid.sh
     chmod +x check_machine_requirements.sh
     chmod +x machinetester.sh
     ```
3. **Installing jq on Ubuntu or Debian-based Systems**:

     ```bash
     sudo apt update
     sudo apt install jq -y
    ```

### Using `./autoverify_machineid.sh`

1. **Check Machine Requirements**:
   - The `./autoverify_machineid.sh` script is designed to test if a single machine meets the minimum requirements for verification. This is useful for hosts who want to verify their own machines.
   - To test a specific machine by its `machine_id`, use the following command:
     ```bash
     ./autoverify_machineid.sh <machine_id>
     ```
     Replace `<machine_id>` with the actual ID of the machine you want to test.

### Monitoring and Results

- **Progress and Results Logging**:
  - The script logs the progress and results of the tests.
  - Successful results and machines that pass the requirements will be logged in `Pass_testresults.log`.
  - Machines that do not meet the requirements or encounter errors during testing will be logged in `Error_testresults.log`.

- **Understanding the Logs**:
  - **`Pass_testresults.log`**: This file contains entries for machines that successfully passed all tests.
  - **`Error_testresults.log`**: This file contains entries for machines that failed to meet the minimum requirements or encountered errors during testing.

### Example Usage

Here’s how you can run the `autoverify_machineid.sh` script to test a machine with `machine_id` 10921:

```bash
./autoverify_machineid.sh 10921
```

### Troubleshooting

- **API Key Issues**: Ensure your API key is correctly set using `./vast set api-key <your-api-key>`.
- **Permission Denied**: If you encounter permission issues, make sure the script files have executable permissions (`chmod +x <script_name>`).
- **Connection Issues**: Verify your network connection and ensure the Vast.ai CLI can communicate with the Vast.ai servers.

### Summary

By following this guide, you will be able to use the `./autoverify_machineid.sh` script to test individual machines on the Vast.ai marketplace. This process helps ensure that machines meet the required specifications for GPU and system performance, making them candidates for further verification and use in the marketplace.

## Project Components

### Main Scripts

1. **autoverify.sh**: 
   - Coordinates the testing of multiple machines to ensure they meet the minimum requirements.
   - Uses `vastcli` to manage and interact with machines on the Vast.ai platform.
   
2. **autoverify_machineid.sh**:
   - Allows for the testing of a single machine by its `machine_id`.
   - Useful for hosts who want to verify their own machines meet the minimum requirements.

3. **check_machine_requirements.sh**:
   - Checks if a specified machine meets the minimum requirements.
   - Provides detailed feedback on which requirements are not met if any.

### Test Scripts

1. **remote.py**:
   - Starts a service on the machine's port 5000 that monitors and reports the progress of testing scripts.
   - Tests the machine's network setup and ability to communicate effectively.

2. **testAllGpusResNet50.py**:
   - Runs a performance test using ResNet-50 across all GPUs on the machine.
   - Assesses the machine's GPU performance capabilities.

3. **systemreqtest.py**:
   - Checks the system requirements and configurations.
   - Ensures the machine meets the necessary system specifications for GPU tasks.

### Docker Integration

- A Docker image is deployed on the machines that meet the initial requirements.
- This image runs `remote.py` to facilitate remote testing and monitoring.

## Setup and Usage

### Prerequisites

- **vastcli**: Installed on the system running the tests. This CLI tool is used to interact with the Vast.ai platform.
- **Docker**: Installed and configured to run on the target machines.

### Steps to Run the Automated Testing

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Make Scripts Executable**:
   ```bash
   chmod +x autoverify.sh
   chmod +x autoverify_machineid.sh
   chmod +x check_machine_requirements.sh
   chmod +x machinetester.sh
   ```

3. **Run the Main Testing Script**:
   - To test all available unverified machines:
     ```bash
     ./autoverify.sh
     ```
   - To test a single machine by its `machine_id`:
     ```bash
     ./autoverify_machineid.sh <machine_id>
     ```

4. **Monitoring and Results**:
   - The script will automatically handle the machine testing and report progress.
   - Results are logged in `Pass_testresults.log` and `Error_testresults.log`.

### Example Commands

- Check if a machine meets the requirements:
  ```bash
  ./check_machine_requirements.sh <machine_id>
  ```

- Test a specific machine for qualification:
  ```bash
  ./autoverify_machineid.sh <machine_id>
  ```

## Detailed Testing Requirements

The following are the specific requirements tested by each script:

### remote.py
- **Network Setup**: Verifies that the machine's networking is configured correctly and can handle communication on port 5000.
- **Progress Reporting**: Monitors the status and reports back the progress of various tests.

### testAllGpusResNet50.py
- **GPU Performance**: Tests the machine's GPUs using the ResNet-50 model to evaluate their performance capabilities.
- **Multi-GPU Testing**: Ensures that all GPUs in the machine can handle the workload effectively.

### systemreqtest.py
- **System Configuration**: Checks the overall system configuration including CPU, RAM, and disk space.
- **Compatibility**: Ensures the machine meets the necessary system specifications for running GPU-intensive tasks.

## Contributions and Issues

Contributions to improve the testing scripts or Docker setup are welcome. Please open issues on the GitHub repository to report bugs or suggest enhancements.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

