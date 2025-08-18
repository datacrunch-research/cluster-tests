# Cluster Health Check Tests

This repository provides a comprehensive suite of health check tests for users of [DataCrunch Instant Clusters](https://datacrunch.io/instant-clusters). These tests help validate that your cluster meets satisfactory compute and networking performance standards.

## Overview

DataCrunch Instant Clusters provide on-demand access to high-performance computing resources. To ensure your cluster is operating correctly, we've developed these validation tests that cover different layers of a typical ML workload:

- **Container-based tests**: Validate containerized workloads using SLURM with Enroot/Pyxis
- **NCCL communication tests**: Verify high-speed networking and GPU-to-GPU communication
- **Training workload tests**: End-to-end validation of distributed training scenarios

Some of these tests are run during our internal validation process to ensure clusters meet performance benchmarks before delivery.

## Test Categories

### 📦 [Containers](./containers/)
Container-based health checks including:
- Enroot/Pyxis container execution examples
- Multi-node distributed training with TorchTitan
- Docker integration workflows

### 🔗 [NCCL Tests](./nccl-tests/)
Network communication validation including:
- SPACK-based NCCL tests
- HPC-X NCCL benchmark suite
- PyTorch distributed communication tests

### 🚀 [Training Tests](./training-tests/)
End-to-end training validation (coming soon)

## Getting Started

1. **Clone this repository** on your DataCrunch Instant Cluster:
   ```bash
   git clone https://github.com/datacrunch-research/cluster-tests.git
   cd cluster-tests
   ```

2. **Navigate to the test category** you want to run (see individual README files for detailed instructions)

3. **Follow the setup and execution** instructions in each directory

## Prerequisites

- DataCrunch Instant Cluster with SLURM scheduler
- Access to compute nodes with GPUs
- Basic familiarity with SLURM job submission

## Support

If you encounter issues with your DataCrunch Instant Cluster or need assistance with these tests, please contact DataCrunch support.

## Contributing

This repository is maintained by the DataCrunch Research Team. Contributions and feedback are welcome!