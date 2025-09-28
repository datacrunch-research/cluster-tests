#!/bin/bash
#SBATCH --job-name=train_requeue
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00
#SBATCH --output=logs/train_%j.out
#SBATCH --error=logs/train_%j.err
#SBATCH --signal=B:USR1@30   # send SIGUSR1 30s before timeout (for checkpointing)

set -euo pipefail
mkdir -p logs

# Source config for checkpoint directory
. ./config.sh
export CKPT_DIR="$CHECKPOINT_DIR"
mkdir -p "$CKPT_DIR"

echo "[job.sh] Running Python training job..."
srun python train.py