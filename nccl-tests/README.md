# NCCL Tests

This page outlines the tests that you can run on your instant cluster to ensure that it is operating correctly. They are structured to tackle different layers of a typical ML workload. The scripts used in this section can be found on our repo: https://github.com/datacrunch-research/supercomputing-clusters

## NCCL test

Three options are available:

- nccl-tests already built with SPACK
- nccl-tests using NVIDIA HPC-X suite.
- nccl-tests included in torch.

### NCCL test from the system

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

This script can be found on our repository here.

### NCCL from Pytorch

#### Singlenode

Assuming https://github.com/datacrunch-research/supercomputing-clusters has been cloned on `/home/ubuntu/`

```bash
# on supercomputing-clusters/nccl_test
torchrun --standalone --nproc_per_node=8 nccl_torch.py --min-size 512MB --max-size 8GB --num-iters 5 --pin-memory --preallocate
```

#### Multinode

```bash
# on supercomputing-clusters/multinode_torch_distributed
sbatch slurm_multinode_torch_distributed.sh
```