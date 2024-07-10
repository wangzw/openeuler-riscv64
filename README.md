# openEuler on RISC-V

Run openEuler on QEMU simulated RISC-V 64-bit CPU.

# Usage

To run openEuler with RISC-V 64-bit CPU, just start a docker container as following.

```shell
docker run -d  -v /path/to/data:/data \
  -p 3957:3957                        \
  -p 5966:5965                        \
  -e CORE=16                          \
  -e MEMORY=16                        \
  -e DISK=200                         \
  ghcr.io/wangzw/openeuler-24.03-riscv64
```

OpenSSH server daemon will be started soon and its listening port will be forwarded to port `3957`.
A VNC server is listening on port 5965. `root` user's password is `vagrant`
