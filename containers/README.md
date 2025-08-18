# Containers

To run a SLURM script with a container specify the container using the --container-image=ubuntu flag e.g.:

sudo srun --container-image=ubuntu grep PRETTY /etc/os-release
