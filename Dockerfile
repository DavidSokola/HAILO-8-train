
# Use a PyTorch image with CUDA
ARG base_image=pytorch/pytorch:1.7.1-cuda11.0-cudnn8-runtime
FROM $base_image

# Set the timezone
ARG timezone=Europe/Berlin
ENV TZ=$timezone
ENV DEBIAN_FRONTEND=noninteractive

# Set the working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    vim \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure Conda is initialized (already included in the base image)
RUN conda init bash

# Create a Conda environment (optional, but recommended)
RUN conda create -n yolo python=3.8 -y

# Install YOLOv5 and required dependencies
RUN /bin/bash -c "source activate yolo && \
    pip install --no-cache-dir ultralytics roboflow && \
    git clone https://github.com/ultralytics/yolov5.git && \
    cd yolov5 && \
    pip install --no-cache-dir -r requirements.txt"

# Expose Jupyter Notebook port
EXPOSE 8888

# Start Jupyter Notebook inside Conda environment
CMD ["/bin/bash", "-c", "source activate yolo && jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root"]




