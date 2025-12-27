# 🚀 AlienOS Development Environment

[![Rust](https://img.shields.io/badge/Rust-nightly-orange?logo=rust)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> **Alien / ArceOS** 本地开发环境一键配置工具。
> 快速搭建 AlienOS 开发环境，自动配置 RISC-V 仿真器、Rust 工具链及 musl 交叉编译环境。

---

## ⚡ 快速开始 (Quick Start)

本项目仅支持 **Ubuntu 22.04 LTS** 或更高版本。

### 1. 获取代码

```bash
git clone https://github.com/nusakom/Alienos-Environment.git alien-env
cd alien-env
```

### 2. 一键部署

运行根目录下的部署脚本：

```bash
./setup.sh
```

**脚本功能：**
- ✅ 自动安装系统基础依赖 (`build-essential`, `qemu-system-riscv64`, etc.)
- ✅ 安装/更新 Rust nightly 工具链 (`nightly-2025-05-01`)
- ✅ 添加 Rust RISC-V target (`riscv64gc-unknown-none-elf`)
- ✅ 下载并配置 `musl` RISC-V 交叉编译工具链 (至 `/opt/riscv64-linux-musl-cross`)
- ✅ 安装 `elfinfo` 调试工具

### 3. 生效环境

脚本运行完成后，请更新环境变量：

```bash
source ~/.bashrc
```

### 4. 验证安装

```bash
# 检查 Rust
rustc --version
# 输出示例: rustc 1.xx.0-nightly ...

# 检查 QEMU
qemu-system-riscv64 --version
# 输出示例: QEMU emulator version 7.x.x ...

# 检查 musl 工具链
riscv64-linux-musl-gcc --version

# 检查 gen_ksym 工具
gen_ksym --version || echo "gen_ksym 将在首次构建时自动安装"
```

---
### 5. 下载 riscv64-linux-musl
如果遇到 riscv64-linux-musl 下载不成功可以尝试下面链接
install riscv64-linux-musl: https://musl.cc/

---

## 🔧 构建 AlienOS

环境配置完成后，您可以开始构建 AlienOS：

### 获取 AlienOS 源码

```bash
git clone https://github.com/Godones/Alien.git
cd Alien
```

### 构建和运行

```bash
# 构建并运行 AlienOS
make run
```

### 常见构建问题

#### 依赖解析错误 ✅ 已修复
如果遇到 `scheduler` 包找不到的错误：

**错误信息**：
```
error: no matching package named `scheduler` found
location searched: Git repository https://github.com/rcore-os/arceos
required by package `smpscheduler`
```

**原因**：`smpscheduler` 依赖寻找名为 `scheduler` 的包，但 arceos 仓库中不存在该包。实际的调度器功能在 `axsched` 包中（发布在 crates.io）。

**解决方案**：确保 `Alien/Cargo.toml` 中包含正确的补丁配置：

```toml
[patch."https://github.com/rcore-os/arceos"]
scheduler = { package = "axsched", version = "0.3" }
```

**验证修复**：
```bash
cd Alien
rm -f Cargo.lock
cargo update
# 应该看到依赖成功解析，没有 scheduler 相关错误
```

#### 文件系统挂载错误 ✅ 已修复
如果遇到 `mkdir: cannot create directory './diskfs/tests': File exists` 错误：

**错误信息**：
```
copying kallsyms to /tests
mkdir: cannot create directory './diskfs/tests': File exists
make: *** [Makefile:137: copy_kallsyms] Error 1
```

**原因**：Makefile 在复制 kallsyms 文件时尝试创建已存在的 tests 目录。

**解决方案**：确保 `Alien/Makefile` 中的 `copy_kallsyms` 目标包含 `mkdir -p` 命令：

```makefile
copy_kallsyms:
	@-sudo umount $(FSMOUNT)
	@-sudo rm -rf $(FSMOUNT)
	@-mkdir $(FSMOUNT)
	@sudo mount $(IMG) $(FSMOUNT)
	@sudo mkdir -p $(FSMOUNT)/tests  # 确保 tests 目录存在
	@echo "copying kallsyms"
	sudo cp kallsyms $(FSMOUNT)/kallsyms
	@echo "copying kallsyms done"
	@make unmount
	@rm kallsyms
```

**临时解决方案**（如果不想修改 Makefile）：
```bash
sudo umount ./diskfs 2>/dev/null || true
rm -rf ./diskfs
rm -f Cargo.lock
make clean
make run
```

## 🛠 工具链清单

部署脚本将自动配置以下核心组件：

| 组件 | 版本/说明 | 用途 |
|------|-----------|------|
| **Rust Toolchain** | `nightly-2025-05-01` | AlienOS 内核编译 |
| **QEMU** | `qemu-system-riscv64` | RISC-V 系统仿真运行 |
| **GNU Toolchain** | `gcc-riscv64-linux-gnu` | 内核链接与基础编译 |
| **Musl Toolchain** | `riscv64-linux-musl-cross` | 用户态程序与 Libc 编译 |
| **Elfinfo** | `latest` | `trace_exe` 依赖分析工具 |
| **Gen_ksym** | `latest` | 内核符号生成工具 (首次构建时自动安装) |

---

## ⚠️ 注意事项

1. **Root 权限**：脚本在安装系统包和 musl 工具链时需要 `sudo` 权限。
2. **网络环境**：脚本需要从 GitHub 和 musl.cc 下载文件，请确保网络连接畅通。
3. **Rust 版本**：为了保证兼容性，锁定使用 `nightly-2025-05-01`。
4. **磁盘空间**：确保至少有 5GB 可用磁盘空间用于工具链和构建缓存。
5. **依赖管理**：首次构建时会自动安装 `gen_ksym` 等工具，请耐心等待。

---

## 🔍 故障排除

### 构建成功标志

当构建成功时，你应该看到类似以下的输出：

```
Compiling kernel v0.1.0 (/path/to/Alien/kernel)
warning: `kernel` (lib) generated 2 warnings
Finished `release` profile [optimized] target(s) in 21.47s
Generating kernel symbols at compile
copying kallsyms
copying kallsyms done
```

### 构建失败常见问题

#### 1. 依赖解析错误
**错误信息**：`error: no matching package named 'scheduler' found`

**解决方案**：
```bash
# 检查 Cargo.toml 补丁配置
grep -A 2 "patch.*arceos" Cargo.toml
# 应该包含: scheduler = { package = "axsched", version = "0.3" }
```

#### 2. 文件系统错误
**错误信息**：`mkdir: cannot create directory './diskfs/tests': File exists`

**解决方案**：
```bash
# 清理构建缓存
rm -f Cargo.lock
sudo umount ./diskfs 2>/dev/null || true
rm -rf ./diskfs
make clean
```

#### 3. 工具链缺失
**错误信息**：`command not found: gen_ksym` 或 `command not found: riscv64-linux-musl-gcc`

**解决方案**：
```bash
# 重新运行环境配置
source ~/.bashrc
# 或重新运行安装脚本
./setup.sh
```

#### 4. QEMU 启动失败
**错误信息**：QEMU 相关错误

**解决方案**：
```bash
# 检查 QEMU 版本
qemu-system-riscv64 --version
# 确保版本 >= 7.0

# 检查内核文件是否生成
ls -la kernel-qemu
```

---

## � 更新日志

### 2025-01-27
- ✅ 修复了 `scheduler` 依赖解析问题
  - 添加了 `axsched` 包的正确补丁配置
  - 解决了 `smpscheduler` 无法找到 `scheduler` 包的问题
- ✅ 修复了 `diskfs/tests` 目录创建冲突
  - 更新了 Makefile 中的 `copy_kallsyms` 目标
  - 使用 `mkdir -p` 避免目录已存在时的错误
- 📚 完善了故障排除文档
  - 添加了详细的错误信息和解决方案
  - 提供了构建成功的标志说明

---

## 📬 联系与反馈

如有问题，请提交 [Issue](https://github.com/nusakom/Alienos-Docker/issues) 或联系维护者。
