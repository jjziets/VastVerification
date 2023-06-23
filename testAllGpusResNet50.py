import torch.nn as nn
from torch.autograd import Variable
from torchvision.models.resnet import resnet18
import torch
import time
import numpy as np
import sys

torch.backends.cudnn.benchmark = True

WARM_UP = 5
NUM_STEP = 20

def main():
    NUM_GPUS = torch.cuda.device_count()

    # Get total GPU memory
    total_gpu_memory = torch.cuda.get_device_properties(0).total_memory * NUM_GPUS

    benchmark = {}
    model_failed = False  # Variable to track if the model execution failed
    # Start from the maximum possible batch size (2**16 = 65536)
    for exp in range(16, 3, -1):  # from 65536 to 16
        batch_size = 2 ** exp

        if not model_failed:  # Only run the estimation if the model did not fail on the previous batch size
            # Calculate approximate memory required for the next batch size
            try:
                # Run a small model with a batch size of 1
                small_model = resnet18().cuda()
                small_input = Variable(torch.randn(1, 3, 224, 224)).cuda()
                small_model(small_input)
                memory_for_batch_1 = torch.cuda.memory_allocated()
                del small_model, small_input
                torch.cuda.empty_cache()  # Clear GPU memory cache
                #time.sleep(5)  # suspend execution for 5 seconds
                # Extrapolate to the batch size we're testing
                estimated_memory_required = memory_for_batch_1 * batch_size  * 0.5 # Added a safety factor
                if estimated_memory_required > total_gpu_memory:
                    print('Skipping batch size %i due to memory constraints.' % batch_size)
                    continue
            except:
                print('Failed to estimate memory requirements for batch size %i.' % batch_size)
                continue

        try:
            torch.cuda.empty_cache()  # Clear GPU memory cache
            time.sleep(5)
            benchmark[batch_size] = []
            print('Benchmarking ResNet50 on batch size %i with %i GPUs' % (batch_size, NUM_GPUS))
            model = resnet18()
            if NUM_GPUS > 1:
                model = nn.DataParallel(model)
            model.cuda()
            model.eval()

            img = Variable(torch.randn(batch_size, 3, 224, 224)).cuda()
            durations = []
            for step in range(NUM_STEP + WARM_UP):
                # test
                torch.cuda.synchronize()
                start = time.time()
                model(img)
                torch.cuda.synchronize()
                end = time.time()
                if step >= WARM_UP:
                    duration = (end - start) * 1000
                    durations.append(duration)
            benchmark[batch_size].append(durations)
            del model
            torch.cuda.empty_cache()  # Clear GPU memory cache
            model_failed = False  # Model run successful, reset the model_failed flag
            sys.exit(0)  # Successful run, exit with code 0

        except RuntimeError as e:
            if 'out of memory' in str(e):
                print('Failed to execute the model with batch size %i due to memory constraints' % batch_size)
                torch.cuda.empty_cache()  # Clear GPU memory cache
                model_failed = True  # Model run failed, set the model_failed flag
                continue
            else:
                raise e

    # If we reach here, all batch sizes failed
    print('Failed to execute the model with any batch size')
    sys.exit(1)  # Exit with failure code

if __name__ == '__main__':
    main()
