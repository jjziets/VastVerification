#!/usr/bin/env bash
#
# build_and_push.sh
#
# Purpose: Compile GPUburn Docker image, extract binaries, build the test image,
#          and push it to the registry.
set -e  # Exit script immediately on any error
echo ">>> Moving into gpu-burn folder..."
cd build_gpuburn/gpu-burn/
echo ">>> Building gpu_burn Docker image and extracting binaries..."
./build_gpu_burn.sh
echo ">>> Copying gpu_burn and compare.ptx back to main folder..."
cp gpu_burn ../../
cp compare.ptx ../../
cd ../../
docker build -t vastai/test:selftest .
docker push vastai/test:selftest
