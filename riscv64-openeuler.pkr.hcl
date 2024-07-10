packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "riscv64" {

  iso_url          = "https://mirror.sjtu.edu.cn/openeuler/openEuler-24.03-LTS/ISO/riscv64/openEuler-24.03-LTS-riscv64-dvd.iso"
  iso_checksum     = "sha256:f49a5da648c53af30aa1a5bcc784685d75baca08743c840889bff32655b6a4e1"
  iso_target_path  = "download/openEuler-24.03-LTS-riscv64-dvd.iso"
  output_directory = "output"
  vm_name          = "riscv64"
  shutdown_command = "shutdown -P now"
  disk_size        = "10G"
  format           = "raw"
  accelerator      = "tcg"
  efi_firmware_code= "files/RISCV_VIRT_CODE.fd"
  efi_firmware_vars= "files/RISCV_VIRT_VARS.fd"
  disk_interface   = "virtio"
  cdrom_interface  = "virtio"
  headless         = false
  disk_image       = false
  machine_type     = "virt"
  memory           = 4096
  cpus             = 4
  net_device       = "virtio-net"
  vnc_port_min     = 5965
  vnc_port_max     = 5965
  qemuargs         = [
    ["-drive", "file=output/riscv64,if=virtio,cache=writeback,discard=ignore,format=raw"],
    [
      "-drive",
      "file=download/openEuler-24.03-LTS-riscv64-dvd.iso,if=virtio,index=1,id=cdrom0,media=cdrom"
    ],
    ["-device", "virtio-net,netdev=user.0"],
    ["-device", "virtio-gpu"],
    ["-device", "nec-usb-xhci,id=xhci,addr=0x1b"],
    ["-device", "usb-tablet,id=tablet,bus=xhci.0,port=1"],
    ["-device", "usb-kbd,id=keyboard,bus=xhci.0,port=2"],
    ["-blockdev", "node-name=pflash0,driver=file,read-only=on,filename=files/RISCV_VIRT_CODE.fd"],
    ["-blockdev", "node-name=pflash1,driver=file,filename=files/RISCV_VIRT_VARS.fd"],
    ["-machine", "type=virt,accel=tcg,pflash0=pflash0,pflash1=pflash1,acpi=off"],
  ]
  qemu_binary         = "qemu-system-riscv64"
  cpu_model           = "rv64"
  use_default_display = true
  http_directory      = "files"
  communicator        = "ssh"
  ssh_username        = "root"
  ssh_password        = "vagrant"
  ssh_timeout         = "200m"
  boot_wait           = "10s"
  boot_steps          = [
    ["<up>e", "Edit boot command"],
    ["<down><down><down><left>", "Move to end of boot command line"],
    [" net.ifnames=0 inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/riscv64-ks.cfg", "Edit boot command line"],
    ["<leftCtrlOn>x<rightCtrlOff>", "Start installation"]
  ]
}

build {
  sources = ["source.qemu.riscv64"]

  provisioner "shell" {
    inline = [
      "set -x",
      "yum-config-manager --disable debuginfo source update-source",
      "yum install -y cloud-init cloud-init-help cloud-utils-growpart",
      "systemctl enable cloud-init",
      "echo 'policy: enabled'>/etc/cloud/ds-identify.cfg",
      "yum clean all",
      "rm -rf /var/cache/yum",
      "dd if=/dev/zero of=/EMPTY bs=1M || :",
      "/usr/bin/rm -f /EMPTY"
    ]
  }

  provisioner "file" {
    source      = "files/cloud.cfg"
    destination = "/etc/cloud/cloud.cfg"
  }

  post-processor "shell-local" {
    inline = [
      "qemu-img convert -c -f raw -O qcow2 output/riscv64 output/openeuler-riscv64-24.03.qcow2",
    ]
  }
}
