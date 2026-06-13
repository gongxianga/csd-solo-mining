# Compute Substrate Solo 挖矿工具

一键安装和启动 Compute Substrate (CSD) solo 挖矿的完整脚本。

## 快速开始

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/install.sh | bash
```

或手动安装：

```bash
git clone https://github.com/gongxianga/csd-solo-mining.git
cd csd-solo-mining
chmod +x install.sh
./install.sh
```

### 启动挖矿

安装完成后，进入安装目录：

```bash
cd ~/csd-solo-miner
```

#### 方式一：交互式菜单（推荐）

```bash
./menu.sh
```

菜单功能包括：
- 🚀 一键启动单显卡/多显卡挖矿
- 🛑 停止挖矿
- 📊 实时查看日志
- 🔄 重启挖矿
- 📈 查看运行状态
- ⚙️ 自动后台运行（关闭SSH不会终止）

#### 方式二：命令行启动

**单显卡挖矿：**
```bash
./start-mining.sh 0x你的钱包地址
```

**多显卡挖矿（4张显卡）：**
```bash
./start-multi-gpu.sh 0x你的钱包地址 4
```

**停止挖矿：**
```bash
./stop-mining.sh
```

**查看日志：**
```bash
# 单显卡
tail -f miner.log

# 多显卡
tail -f miner1.log
```

## 系统要求

- **操作系统**: Ubuntu 20.04+ / Debian 11+
- **CPU**: 4+ 核心
- **内存**: 8-16 GB
- **存储**: SSD（推荐至少50GB可用空间）
- **网络**: 稳定的互联网连接

## 功能特性

- ✅ 交互式菜单，一键启动管理
- ✅ 后台运行，关闭SSH不会终止
- ✅ 自动安装所有依赖（Rust、构建工具等）
- ✅ 自动编译最新版本（v1.0.4）
- ✅ 自动下载和验证创世文件
- ✅ 支持单显卡和多显卡挖矿
- ✅ 多显卡并行挖矿支持
- ✅ 自动配置引导节点
- ✅ 完整的日志输出和管理
- ✅ 实时状态监控

## 目录结构

```
~/csd-solo-miner/
├── target/release/csd      # 编译好的节点程序
├── genesis.bin             # 创世文件
├── menu.sh                 # 交互式菜单脚本（推荐）
├── start-mining.sh         # 单显卡启动脚本
├── start-multi-gpu.sh      # 多显卡启动脚本
├── stop-mining.sh          # 停止脚本
├── cs.db/                  # 单显卡数据目录
├── cs_gpu1.db/             # 多显卡数据目录
├── miner.log               # 单显卡日志文件
└── miner*.log              # 多显卡日志文件
```

## 常见问题

### 如何获取钱包地址？

钱包地址是以太坊格式的地址（0x开头），你可以使用：
- MetaMask 钱包
- 任何以太坊兼容钱包
- CSD 官方钱包工具

### 编译需要多长时间？

首次编译通常需要 10-30 分钟，具体取决于你的 CPU 性能。

### 如何检查是否在挖矿？

查看日志文件：
```bash
tail -f ~/csd-solo-miner/miner1.log
```

你应该看到类似的输出，包含挖矿活动和区块信息。

### 多显卡挖矿如何工作？

脚本会启动多个独立的挖矿进程，每个进程使用不同的端口和数据目录。这样可以充分利用多核 CPU 和多张显卡的算力。

### 如何更新到最新版本？

```bash
rm -rf ~/csd-solo-miner
./install.sh
```

## 相关链接

- [Compute Substrate 官网](https://computesubstrate.org)
- [区块浏览器](https://explorer.computesubstrate.org)
- [GitHub 仓库](https://github.com/compute-substrate/compute-substrate)
- [Discord 社区](https://discord.gg/Gr9gCjzC9e)

## 许可证

MIT License

## 免责声明

本工具仅供学习和研究使用。挖矿有风险，投资需谨慎。使用本工具产生的任何损失，作者不承担责任。
