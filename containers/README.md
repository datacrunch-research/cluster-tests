# Containers

To run a SLURM script with a container, import the container using:

```bash
enroot import docker://ubuntu:22.04
```

Then specify the container using the `--container-image=ubuntu:22.04` flag:

```bash
sudo srun --container-image=ubuntu:22.04 grep PRETTY /etc/os-release
```

Alternatively to use a custom image built in dockerd:

1. Build a custom dockerfile with:

```bash
docker build -f <file.dockerfile> -t <name:tag> .
```

2. [Import](https://github.com/NVIDIA/enroot/blob/master/doc/cmd/import.md) dockerd image to Enroot (Can be done with `docker://IMAGE:TAG` from registry)

```bash
enroot import dockerd://<name:tag>
```

3. Use Pyxis’ flags pointing to the <name:tag>.sqsh

```bash
--container-image=<name:tag>.sqsh
```
