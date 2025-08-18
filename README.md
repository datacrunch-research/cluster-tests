# Cluster Health Check Tests

This repository provides health check tests for users of [DataCrunch Instant Clusters](https://datacrunch.io/instant-clusters). These tests help validate that your cluster meets satisfactory compute and networking performance standards.

## Overview

DataCrunch Instant Clusters provide on-demand access to high-performance computing resources. To ensure your cluster is operating correctly, we've developed these validation tests that cover different layers of a typical ML workload:

- **Container-based tests**: Validate containerized workloads using SLURM with Enroot/Pyxis.
- **NCCL communication tests**: Verify high-speed networking and GPU-to-GPU communication.
- **Training workload tests**: End-to-end validation of distributed training scenarios.

Some of these tests are run during our internal validation process to ensure clusters meet performance benchmarks before delivery.

## Getting Started

1. **Clone this repository** on your DataCrunch Instant Cluster:
   ```bash
   git clone https://github.com/datacrunch-research/cluster-tests.git
   cd cluster-tests
   ```

2. **Navigate to the test category** you want to run (see individual README files for detailed instructions).

3. **Follow the setup and execution** instructions in each directory.

