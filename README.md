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
2. **Vast.ai **: The machine should be listed on the vast marketplace.
3. **Ubuntu OS**: The scripts are designed to run on Ubununt 20.04 or newer.

### Setup and Installation

1. **Download and Setup `vastcli`**:
   - Download the Vast.ai CLI tool using the following command:
     ```bash
     wget https://raw.githubusercontent.com/vast-ai/vast-python/master/vast.py -O vast
     chmod +x vast
     ```

   - Set your Vast.ai API key:
     ```bash
     ./vast set api-key 6189d1be9f15ad2dced0ac4e3dfd1f648aeb484d592e83d13aaf50aee2d24c07
     ```

2. **Download autoverify_machineid.sh**:
   - Use wget to download autoverify_machineid.sh to your local machine:
     ```bash
     wget https://github.com/jjziets/VastVerification/releases/download/0.4-beta/autoverify_machineid.sh
     ```
     
3. **Make Scripts Executable**:
   - Change the permissions of the main scripts to make them executable:
     ```bash
     chmod +x autoverify_machineid.sh
     ```

### Using `./autoverify_machineid.sh`

1. **Check Machine Requirements**:
   - The `./autoverify_machineid.sh` script is designed to test if a single machine meets the minimum requirements for verification. This is useful for hosts who want to verify their own machines.
   - To test a specific machine by its `machine_id`, use the following command:
     ```bash
     ./autoverify_machineid.sh <machine_id>
     ```
     Replace `<machine_id>` with the actual ID of the machine you want to test.

2. **To Ignore Requirements Check**:
    ```bash
    ./autoverify_machineid.sh --ignore-requirements <machine_id>
    ```
    This command runs the tests for the machine, regardless of whether it meets the minimum requirements.

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

Here’s a summary of what each script checks or does:

### 1. **Bash Script: Machine Requirements Checker**
   - **Purpose**: This script checks whether a machine (identified by a given `machine_id`) meets specific requirements for availability, CUDA version, reliability, direct ports, PCIe bandwidth, internet speeds, and GPU RAM.
   - **Checks**:
     - If the machine is found and is rentable.
     - CUDA version is at least 12.4.
     - Reliability is greater than 0.90.
     - The number of direct ports is greater than 3.
     - PCIe bandwidth is greater than 3.
     - Internet download and upload speeds are both greater than 10 Mb/s.
     - GPU RAM is greater than 7 GB.
   - **Output**: If all requirements are met, it confirms the machine is suitable; otherwise, it lists which requirements are not met.

### 2. **Python Script: `remote.py`**
   - **Purpose**: This script sets up a simple HTTPS server that serves the contents of a `progress.log` file and runs a series of system tests.
   - **Functions**:
     - **Generates a self-signed SSL certificate** if it doesn't exist.
     - **Serves the `progress.log` file** on port 5000 over HTTPS.
     - **Logs test progress** to `progress.log`.
     - **Runs a sequence of tests**:
       1. **System requirements test** (using `systemreqtest.py`).
       2. **ResNet50 benchmark test** on all GPUs (using `testAllGpusResNet50.py`).
       3. **Simultaneous stress tests** using `stress-ng` and `gpu-burn`.
     - Logs the results of these tests, noting any failures.

### 3. **Python Script: `systemreqtest.py`**
   - **Purpose**: This script checks if the system meets minimum hardware requirements for GPU-intensive tasks.
   - **Checks**:
     - The number of GPUs and verifies they are of the same model.
     - At least 98% of VRAM is free on each GPU.
     - Total system RAM is greater than the sum of all GPUs' VRAM.
     - The system has at least two CPU cores per GPU.
   - **Output**: Confirms whether the system meets the requirements or identifies any deficiencies.

### 4. **Python Script: `testAllGpusResNet50.py`**
   - **Purpose**: This script benchmarks the ResNet50 model on all available GPUs to determine the maximum feasible batch size for training.
   - **Checks**:
     - Tries different batch sizes, starting from the largest, and tests if the GPU can handle them.
     - Estimates if the available GPU memory is sufficient for the batch size.
     - Runs the ResNet50 model with the tested batch size and records execution times.
   - **Output**: Identifies the maximum batch size that the system can handle without running out of memory and exits with success or failure depending on the result.

These scripts collectively ensure that the machine meets specific performance criteria, validate the hardware setup, and perform stress tests to confirm system stability under load.

## Contributions and Issues

Contributions to improve the testing scripts or Docker setup are welcome. Please open issues on the GitHub repository to report bugs or suggest enhancements.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

