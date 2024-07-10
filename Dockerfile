FROM ghcr.io/wangzw/qemu:8.2.2

ADD files/RISCV_VIRT_CODE.fd /firmware/RISCV_VIRT_CODE.fd
ADD download/RISCV_VIRT_VARS.fd /firmware/RISCV_VIRT_VARS.fd
ADD download/openeuler-riscv64-24.03.qcow2 /image/openeuler-riscv64-24.03.qcow2

ADD files/start.sh /usr/bin/start.sh
CMD ["/usr/bin/start.sh"]
