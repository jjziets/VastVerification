import torch
import os
import sys
import psutil

def main():
    # Number of GPUs
    NUM_GPUS = torch.cuda.device_count()

    # VRAM of GPUs
    total_vram = sum([torch.cuda.get_device_properties(i).total_memory for i in range(NUM_GPUS)])

    # Check that at least 98% of VRAM is free on each GPU
    for i in range(NUM_GPUS):
        vram = torch.cuda.get_device_properties(i).total_memory
        vram_used = torch.cuda.memory_allocated(i) + torch.cuda.memory_reserved(i)
        if vram_used > 0.02 * vram:
            print(f'Less than 98% of VRAM is free on GPU {i}.')
            return 1

    # System total memory (RAM)
    total_ram = psutil.virtual_memory().total

    # Number of CPU cores
    num_cpu_cores = psutil.cpu_count(logical=False)

    if total_ram < total_vram:
        print('System total memory is less than the sum of all the GPUs VRAM.')
        return 1

    if num_cpu_cores < 2 * NUM_GPUS:
        print('There are less than 2 CPU cores per GPU.')
        return 1

    print('System meets the minimum requirements.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
