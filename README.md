# Project Name: Remote System Requirements and GPU Tests

This project allows you to remotely check whether a system meets certain requirements and then, if it does, perform a GPU test.

## Repository Structure

Here is a quick overview of the main files and directories in this repository:

- **Dockerfile**: This is the Docker configuration file used to create a Docker image for the remote server. It contains instructions for setting up the necessary environment, including installing required packages and copying the necessary scripts.

- **testAllGpusResNet50.py**: This Python script performs a ResNet50 test on all GPUs available on the system. It writes the test results into a log file.

- **systemreqtest.py**: This Python script checks if the system meets certain requirements, such as having a specific version of Python, certain libraries installed, sufficient memory, and so on. It returns an exit status of 0 if the requirements are met, and 1 otherwise.

- **remote.sh**: This shell script is run on the remote server. It starts a netcat (nc) listener which allows a client to connect and receive the status of the system requirements test and GPU test. It first runs the system requirements test using systemreqtest.py, and then if the requirements are met, it runs the GPU test using testAllGpusResNet50.py.

- **local.sh**: This shell script is run on the local client machine. It connects to the remote server using netcat (nc), sends a command to start the tests, and retrieves the test status messages.

## How to use

1. Start by building the Docker image on the remote server using the Dockerfile provided.

    ```bash
    docker build -t jjziets/vasttest:latest .
    docker push  jjziets/vasttest:latest

    ```

2. Once the Docker image is built, start a Docker container with the image. This will automatically start the remote.sh script and thus the netcat listener.

    ```bash
    docker run mytestimage
    ```

3. On the local client machine, run the local.sh script to connect to the remote server and start the tests. The script will print the test status messages retrieved from the server.

    ```bash
    ./local.sh 192.168.0.10 5000  # Replace with the actual IP and port of your remote server
    ```

4. The test results will be saved in a `progress.log` file on the remote server and in a `remoteprogress.log` file on the local client machine. You can check these files to see the results of the system requirements test and the GPU test.

Please note that these scripts are simplified examples and may need to be adapted to your specific use case. For example, you may need to modify the system requirements in systemreqtest.py or the ResNet50 test in testAllGpusResNet50.py to suit your needs.
