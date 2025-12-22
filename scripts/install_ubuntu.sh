#!/usr/bin/env bash
set -e

echo "[+] AlienOS local environment setup (Ubuntu)"

# -------------------------
# 基础环境
# -------------------------
sudo apt update
sudo apt install -y \
  curl wget git build-essential pkg-config libssl-dev \
  ca-certificates sudo vim \
  gdb-multiarch \
  device-tree-compiler \
  u-boot-tools \
  dosfstools e2fsprogs \
  python3 python3-pip \
  xz-utils file

# -------------------------
# QEMU (RISC-V)
# -------------------------
sudo apt install -y \
  qemu-system-misc \
  qemu-system-riscv64

qemu-system-riscv64 --version

# -------------------------
# GNU RISC-V 工具链
# -------------------------
sudo apt install -y \
  gcc-riscv64-linux-gnu \
  binutils-riscv64-linux-gnu

# -------------------------
# Rust + rustup
# -------------------------
if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y
fi

source $HOME/.cargo/env

# -------------------------
# Rust nightly
# -------------------------
rustup toolchain install nightly-2025-05-01
rustup default nightly-2025-05-01

rustup component add \
  rust-src \
  llvm-tools-preview \
  rustfmt \
  clippy

rustup target add riscv64gc-unknown-none-elf

# -------------------------
# musl RISC-V 工具链
# -------------------------
if [ ! -d "/opt/riscv64-linux-musl-cross" ]; then
  wget -O /tmp/riscv64-linux-musl-cross.tgz \
    https://musl.cc/riscv64-linux-musl-cross.tgz
  sudo tar -xzf /tmp/riscv64-linux-musl-cross.tgz -C /opt
  rm /tmp/riscv64-linux-musl-cross.tgz
fi

echo 'export PATH=/opt/riscv64-linux-musl-cross/bin:$PATH' >> ~/.bashrc

# -------------------------
# elfinfo
# -------------------------
cargo install --git https://github.com/os-module/elfinfo

echo "[✓] AlienOS local environment ready"