import argparse
import os
import torch
import torch.distributed as dist
import torch.multiprocessing as mp
from datetime import timedelta


DEFAULT_TIMEOUT = timedelta(seconds=10)


def func(args):
    print(torch.randn(1))

def run(main_func, backend, num_machines, num_gpus, machine_rank, dist_url, args=()):
    world_size = num_machines * num_gpus

    mp.spawn(
        distributed_worker,
        nprocs=num_gpus,
        args=(
            main_func,
            backend,
            world_size,
            num_gpus,
            machine_rank,
            dist_url,
            args,
        ),
        daemon=False,
    )

def distributed_worker(
    local_rank,
    main_func,
    backend,
    world_size,
    num_gpus_per_machine,
    machine_rank,
    dist_url,
    args,
    timeout=DEFAULT_TIMEOUT,
):
    LOCAL_PROCESS_GROUP = None

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is not available. Please check your installation.")

    global_rank = machine_rank * num_gpus_per_machine + local_rank
    try:
        dist.init_process_group(
            backend=backend,
            init_method=dist_url,
            world_size=world_size,
            rank=global_rank,
            timeout=timeout,
        )
    except Exception as e:
        print(f"Process group URL: {dist_url}")
        raise e


    dist.barrier()

    print(f"Global rank {global_rank}.")
    print("Synchronized GPUs.")

    if num_gpus_per_machine > torch.cuda.device_count():
        raise RuntimeError
    torch.cuda.set_device(local_rank)

    # Setup the local process group (which contains ranks within the same machine)
    if LOCAL_PROCESS_GROUP is not None:
        raise RuntimeError

    num_machines = world_size // num_gpus_per_machine

    for idx in range(num_machines):
        ranks_on_i = list(range(idx * num_gpus_per_machine, (idx + 1) * num_gpus_per_machine))
        pg = dist.new_group(ranks_on_i)
        if idx == machine_rank:
            LOCAL_PROCESS_GROUP = pg

    main_func(args)


def main():
    torch.set_num_threads(1)
    os.environ["OMP_NUM_THREADS"] = "1"
    os.environ["NCCL_DEBUG"] = "INFO"

    print(f"CUDA {torch.version.cuda} - cuDNN {torch.backends.cudnn.version()} - cudaNCCL {torch.cuda.nccl.version()}")
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", type=str, default="NCCL", help="'gloo' or 'NCCL'.")
    parser.add_argument("--num-gpus", type=int, default=1, help="# GPUs per machine.")
    parser.add_argument("--num-machines", type=int, default=1, help="# of machines.")
    parser.add_argument(
        "--machine-rank",
        type=int,
        default=0,
        help="the rank of this machine (unique per machine).",
    )

    port = 1234
    parser.add_argument(
        "--dist-url",
        type=str,
        default=f"tcp://127.0.0.1:{port}",
        help="initialization URL for pytorch distributed backend. See "
        "https://pytorch.org/docs/stable/distributed.html for details.",
    )

    args = parser.parse_args()

    run(
        main_func=func,
        backend=args.backend,
        num_machines=args.num_machines,
        num_gpus=args.num_gpus,
        machine_rank=args.machine_rank,
        dist_url=args.dist_url,
        args=()
    )


if __name__ == '__main__':
    main()
