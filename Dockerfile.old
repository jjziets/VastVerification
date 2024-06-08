# Start with the specified PyTorch image
FROM pytorch/pytorch:1.9.0-cuda11.1-cudnn8-runtime

# Update the system and install necessary packages
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get install -y python3 python3-pip git netcat

# Update Python and PyTorch to their latest versions
RUN apt-get upgrade -y python3 && \
    pip3 install --upgrade torch psutil

# Clone the specified repository
#RUN git clone https://github.com/jjziets/pytorch-benchmark-volta.git

# Set the working directory in the container
WORKDIR /pytorch-benchmark-volta

# Copy the requirements file into the container
COPY requirements.txt .
COPY remote.sh .
COPY testAllGpusResNet50.py .
COPY systemreqtest.py .

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt



# Make the script executable
RUN chmod +x remote.sh

# Define the command to run when the container is started
CMD ["./remote.sh"]


