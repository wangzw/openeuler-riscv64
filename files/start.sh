#!/usr/bin/env bash

set -euxo pipefail

CORE=${CORE-4}
MEMORY=${MEMORY-8}
DISK=${DISK-50}

if [ ${MEMORY} -gt 4 ] && [ $((MEMORY % 4)) -ne 0  ]; then
  echo "Invalid memory ${MEMORY}G, must be factor of 4"
  false
fi

if [ ${MEMORY} -gt 64 ]; then
  echo "Invalid memory ${MEMORY}G, too large"
  false
fi

function create_disk() {
    if [ ! -f /data/openeuler-riscv64-24.03.raw ]; then
      sudo mkdir -p /data/
      sudo chmod 777 /data/
      qemu-img convert -f qcow2 -O raw /image/openeuler-riscv64-24.03.qcow2 /data/openeuler-riscv64-24.03.raw
    fi

    qemu-img resize -f raw /data/openeuler-riscv64-24.03.raw ${DISK}G

    if [ ! -f /data/firmware/RISCV_VIRT_VARS.fd ]; then
      sudo mkdir -p /data/firmware/
      sudo chmod 777 /data/firmware/
      cp -a /firmware/RISCV_VIRT_VARS.fd /data/firmware/RISCV_VIRT_VARS.fd
    fi
}

function numa() {
    local args=""
    local factor=4

    if [ ${MEMORY} -gt 16 ]; then
      factor=8
    fi

    if [ ${MEMORY} -gt 32 ]; then
      factor=16
    fi

    local n=$((MEMORY / factor))
    for (( m=1; m<=$n; m++ )); do
      args="$args -object memory-backend-ram,size=${factor}G,id=ram$m -numa node,memdev=ram$m"
    done

    echo "$args"
}

function riscv64() {
    sudo chmod a+rw /firmware/RISCV_VIRT_VARS.fd
    exec qemu-system-riscv64 \
      -name riscv64 \
      -smp ${CORE} \
      -m ${MEMORY}G \
      -cpu rv64 \
      $(numa) \
      -machine type=virt,accel=tcg \
      -device nec-usb-xhci,id=xhci,addr=0x1b \
      -device usb-tablet,id=tablet,bus=xhci.0,port=1 \
      -device usb-kbd,id=keyboard,bus=xhci.0,port=2 \
      -device virtio-gpu \
      -device virtio-net,netdev=user.0 \
      -drive file=/data/openeuler-riscv64-24.03.raw,if=virtio,cache=writeback,format=raw \
      -blockdev node-name=pflash0,driver=file,read-only=on,filename=/firmware/RISCV_VIRT_CODE.fd \
      -blockdev node-name=pflash1,driver=file,filename=/data/firmware/RISCV_VIRT_VARS.fd \
      -machine type=virt,accel=tcg,pflash0=pflash0,pflash1=pflash1,acpi=off \
      -netdev user,id=user.0,hostfwd=tcp::3957-:22 \
      -vnc 0.0.0.0:65
}

function start() {
    create_disk
    riscv64
}

start