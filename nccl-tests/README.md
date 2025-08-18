
## NCCL test

Three options are available:

- nccl-tests already built with SPACK
- nccl-tests using NVIDIA HPC-X suite.
- nccl-tests using torch.

### NCCL test from the SPACK module

At `/home/ubuntu/`:

```bash
sbatch all_reduce_example_slurm.job
```

### NCCL from hpcx module

First, we load the HPC-X module:

```bash
modules load hpcx
```

Then we need to compile nccl-tests with the HPC-X binaries:

```bash
git clone https://github.com/NVIDIA/nccl-tests.git; \
cd /home/ubuntu/nccl-tests; \
make MPI=1 -j$(nproc);
```

We add hostfile.txt as the list of workernodes to perform the test:

```bash
cat /etc/mpihosts > hostfile.txt
```

Once compiled, we can test it with the following command:

```bash
mpirun -np 16 -N 8 -x NCCL_NET_PLUGIN=/opt/hpcx/nccl_rdma_sharp_plugin/lib/libnccl-net.so -hostfile hostfile.txt ./build/all_reduce_perf -b 512M -e 8G -f 2 -g 1
```

See `hpcx_nccl_test.sh` for a complete example script that automates this process.

### NCCL from Pytorch

We also provide an alternative PyTorch-based NCCL benchmark adapted from [ml-engineering](https://github.com/stas00/ml-engineering) that's easier to set up and only requires PyTorch.

#### Setup (run once)

The cluster uses uv for Python package management. First, set up the PyTorch environment:

```bash
# Setup PyTorch environment (installs PyTorch 2.8 with CUDA 12.9)
bash /home/pytorch.setup.sh

# Activate the environment and install additional packages required by the benchmark
. /home/venv_ubuntu_cu129/bin/activate
pip install matplotlib packaging
```

#### Running the benchmark

```bash
sbatch pytorch_nccl_bench.sh
```

This benchmark (`all_reduce_bench.py`) provides detailed bandwidth measurements and automatically generates plots if matplotlib is available. It measures payload ranges from 32KB to 16GB and provides both algorithm bandwidth (algbw) and bus bandwidth (busbw) results.
