# Start with the specified CUDA image with cuDNN support
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

# Install Python, necessary packages, stress-ng, build-essential for building gpu-burn, and clean up
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
    python3 python3-pip git netcat stress-ng build-essential && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Upgrade psutil and install PyTorch and other dependencies
RUN pip3 install --upgrade psutil && \
    pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu124 && \
    rm -rf /root/.cache/pip /tmp/* /var/tmp/*

# Set the working directory in the container
WORKDIR /pytorch-benchmark-volta

# Copy the requirements file and scripts into the container
COPY requirements.txt .
COPY remote.py .
COPY eccfunction.py .
COPY testAllGpusResNet50.py .
COPY systemreqtest.py .
COPY gpu_burn .
COPY compare.ptx .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip /tmp/* /var/tmp/*

# Define the command to run when the container is started
CMD ["python3 remote.py"]
