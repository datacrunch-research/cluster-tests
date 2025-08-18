#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --gpus-per-node=8
#SBATCH --cpus-per-task=50
#SBATCH --partition=gpus
#SBATCH --job-name=pytorch_nccl_bench
#SBATCH -o /home/ubuntu/slurm_logging/headnode/%x_%j.out
#SBATCH -e /home/ubuntu/slurm_logging/headnode/%x_%j.err

# Setup PyTorch environment
source /home/pytorch.setup.sh

# Install additional packages required by the benchmark
pip install matplotlib packaging

# Check if python is available
which python || which python3
echo "Python version: $(python --version 2>/dev/null || python3 --version)"

# === Compute these HOST-side ===
HEADNODE_HOST=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n1)
MASTER_ADDR=$(getent hosts "$HEADNODE_HOST" | grep -Eo '10\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
MASTER_PORT=$((5000 + SLURM_JOB_ID % 10000))

GPUS_PER_NODE=8
NNODES=2

echo "======== Distributed Config ========"
echo "HEADNODE_HOST: $HEADNODE_HOST"
echo "Resolved MASTER_ADDR: $MASTER_ADDR"
echo "Assigned MASTER_PORT: $MASTER_PORT"
echo "SLURM_JOB_NODELIST: $SLURM_JOB_NODELIST"
echo "GPUS_PER_NODE: $GPUS_PER_NODE"
echo "NNODES: $NNODES"
echo "All Hosts:"
scontrol show hostnames "$SLURM_JOB_NODELIST"
echo "===================================="

# Run the PyTorch NCCL benchmark
srun bash -c "source /home/pytorch.setup.sh && python -u -m torch.distributed.run \
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NNODES \
    --rdzv_endpoint $MASTER_ADDR:$MASTER_PORT \
    --rdzv_backend c10d \
    --max_restarts 0 \
    --tee 3 \
    all_reduce_bench.py"