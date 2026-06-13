#!/bin/bash

set -e

echo "=========================================="
echo "Compute Substrate Solo 挖矿安装脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}建议使用 sudo 运行此脚本${NC}"
fi

# 安装目录
INSTALL_DIR="$HOME/csd-solo-miner"
CSD_VERSION="v1.0.4"

echo -e "${GREEN}[1/6] 安装依赖...${NC}"
sudo apt-get update
sudo apt-get install -y build-essential git curl pkg-config libssl-dev

echo -e "${GREEN}[2/6] 安装 Rust 编译环境...${NC}"
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust 已安装，跳过"
fi

echo -e "${GREEN}[3/6] 下载 Compute Substrate 源码...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo "目录已存在，清理旧文件..."
    rm -rf "$INSTALL_DIR"
fi

git clone --depth 1 --branch $CSD_VERSION https://github.com/compute-substrate/compute-substrate.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${GREEN}[4/6] 编译 CSD 节点（这可能需要 10-30 分钟）...${NC}"
RUSTFLAGS="-C target-cpu=native" cargo build --release

echo -e "${GREEN}[5/6] 下载创世文件...${NC}"
curl -o genesis.bin https://computesubstrate.org/downloads/genesis.bin
curl -o checksums.txt https://computesubstrate.org/downloads/checksums.txt

# 验证文件（可选）
if command -v sha256sum &> /dev/null; then
    echo "验证创世文件..."
    sha256sum genesis.bin
fi

echo -e "${GREEN}[6/6] 创建启动脚本...${NC}"

# 引导节点列表
BOOTNODES="/ip4/141.94.163.242/tcp/18007/p2p/12D3KooWKGhuUhAwGDf3MtqL581h3gttvFg9Z2p1ej9wFTdKfdSM,/ip4/135.125.170.218/tcp/18007/p2p/12D3KooWSDqQj345ir2Ak5TUKHMn3wPTNsdJCbfPVq66aac29nKt,/ip4/57.129.84.73/tcp/18007/p2p/12D3KooWLydGAnXtXH4L37gVZWohAZNvKdFgHwVN4nhUzgrvX8cW,/ip4/158.69.116.36/tcp/17999/p2p/12D3KooWHKcjL8M5snr3GniC8xRtGJGbGhPSdGiqtZNRz6UFj1t3,/ip4/145.239.0.111/tcp/17999/p2p/12D3KooWFsHa5ifqK45Fjd8cYnDkVDN8R8MfjfiETNpEqnbGAEez"

cat > start-mining.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录并切换
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查钱包地址参数
if [ -z "$1" ]; then
    echo "用法: ./start-mining.sh <你的钱包地址>"
    echo "示例: ./start-mining.sh 0x1234567890abcdef1234567890abcdef12345678"
    exit 1
fi

MINER_ADDR=$1

# 引导节点
BOOTNODES="BOOTNODES_PLACEHOLDER"

# 数据目录
DATADIR="cs.db"

# 检查必要文件
if [ ! -f "target/release/csd" ]; then
    echo "错误: 未找到 csd 程序，请检查安装"
    exit 1
fi

if [ ! -f "genesis.bin" ]; then
    echo "错误: 未找到 genesis.bin 文件"
    exit 1
fi

# 启动挖矿
echo "启动 Compute Substrate Solo..."
echo "矿工地址: $MINER_ADDR"
echo "数据目录: $DATADIR"
echo "工作目录: $SCRIPT_DIR"
echo ""

nohup ./target/release/csd node \
  --mine \
  --miner-addr20 $MINER_ADDR \
  --datadir $DATADIR \
  --genesis genesis.bin \
  --rpc 0.0.0.0:8789 \
  --p2p-listen /ip4/0.0.0.0/tcp/18007 \
  --bootnodes $BOOTNODES \
  > miner.log 2>&1 &

# 启动日志清理脚本
if [ -f "$SCRIPT_DIR/log-cleaner.sh" ]; then
    if ! pgrep -f "log-cleaner.sh" > /dev/null; then
        nohup bash "$SCRIPT_DIR/log-cleaner.sh" > /dev/null 2>&1 &
        echo "日志清理程序已启动（每30分钟清理一次）"
    fi
fi

# 启动区块监控脚本
if [ -f "$SCRIPT_DIR/block-monitor.sh" ]; then
    if ! pgrep -f "block-monitor.sh" > /dev/null; then
        nohup bash "$SCRIPT_DIR/block-monitor.sh" > /dev/null 2>&1 &
        echo "区块监控程序已启动（实时监控同步进度和爆块）"
    fi
fi

echo "已在后台启动！"
echo "查看日志: tail -f $SCRIPT_DIR/miner.log"
echo "查看监控: tail -f $SCRIPT_DIR/monitor.log"
echo "停止运行: $SCRIPT_DIR/stop-mining.sh"
EOF

# 替换引导节点
sed -i "s|BOOTNODES_PLACEHOLDER|$BOOTNODES|g" start-mining.sh

chmod +x start-mining.sh

# 创建多显卡挖矿脚本
cat > start-multi-gpu.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录并切换
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查钱包地址参数
if [ -z "$1" ]; then
    echo "用法: ./start-multi-gpu.sh <你的钱包地址> [GPU数量]"
    echo "示例: ./start-multi-gpu.sh 0x1234567890abcdef1234567890abcdef12345678 4"
    exit 1
fi

MINER_ADDR=$1
GPU_COUNT=${2:-4}

# 引导节点
BOOTNODES="BOOTNODES_PLACEHOLDER"

# 检查必要文件
if [ ! -f "target/release/csd" ]; then
    echo "错误: 未找到 csd 程序，请检查安装"
    exit 1
fi

if [ ! -f "genesis.bin" ]; then
    echo "错误: 未找到 genesis.bin 文件"
    exit 1
fi

echo "工作目录: $SCRIPT_DIR"
echo "启动 $GPU_COUNT 个挖矿实例..."
echo ""

for i in $(seq 1 $GPU_COUNT); do
    PORT=$((18000 + i))
    DATADIR="cs_gpu${i}.db"

    echo "启动挖矿实例 $i (端口: $PORT)"

    nohup ./target/release/csd node \
      --mine \
      --miner-addr20 $MINER_ADDR \
      --datadir $DATADIR \
      --genesis genesis.bin \
      --rpc 0.0.0.0:$((8789 + i)) \
      --p2p-listen /ip4/0.0.0.0/tcp/$PORT \
      --bootnodes $BOOTNODES \
      > miner${i}.log 2>&1 &

    echo "实例 $i 已启动，日志: $SCRIPT_DIR/miner${i}.log"
    sleep 2
done

echo ""

# 启动日志清理脚本
if [ -f "$SCRIPT_DIR/log-cleaner.sh" ]; then
    if ! pgrep -f "log-cleaner.sh" > /dev/null; then
        nohup bash "$SCRIPT_DIR/log-cleaner.sh" > /dev/null 2>&1 &
        echo "日志清理程序已启动（每30分钟清理一次）"
    fi
fi

# 启动区块监控脚本
if [ -f "$SCRIPT_DIR/block-monitor.sh" ]; then
    if ! pgrep -f "block-monitor.sh" > /dev/null; then
        nohup bash "$SCRIPT_DIR/block-monitor.sh" > /dev/null 2>&1 &
        echo "区块监控程序已启动（实时监控同步进度和爆块）"
    fi
fi

echo "所有挖矿实例已启动！"
echo "查看日志: tail -f $SCRIPT_DIR/miner1.log"
echo "查看监控: tail -f $SCRIPT_DIR/monitor.log"
echo "停止运行: $SCRIPT_DIR/stop-mining.sh"
EOF

sed -i "s|BOOTNODES_PLACEHOLDER|$BOOTNODES|g" start-multi-gpu.sh
chmod +x start-multi-gpu.sh

# 创建停止脚本
cat > stop-mining.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "停止所有 CSD 挖矿进程..."

if pgrep -f 'csd node' > /dev/null; then
    pkill -f 'csd node'
    sleep 2

    # 再次检查
    if pgrep -f 'csd node' > /dev/null; then
        echo "警告: 部分进程未能停止，尝试强制停止..."
        pkill -9 -f 'csd node'
    fi

    echo "已停止所有挖矿进程"
else
    echo "没有运行中的挖矿进程"
fi

# 停止日志清理进程
if pgrep -f 'log-cleaner.sh' > /dev/null; then
    echo "停止日志清理进程..."
    pkill -f 'log-cleaner.sh'
    echo "日志清理进程已停止"
fi

# 停止区块监控进程
if pgrep -f 'block-monitor.sh' > /dev/null; then
    echo "停止区块监控进程..."
    pkill -f 'block-monitor.sh'
    echo "区块监控进程已停止"
fi
EOF

chmod +x stop-mining.sh

# 创建区块监控和爆块统计脚本
cat > block-monitor.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 统计文件
STATS_FILE="$SCRIPT_DIR/mining-stats.txt"
BLOCKS_FOUND_FILE="$SCRIPT_DIR/blocks-found.log"

# 初始化统计文件
if [ ! -f "$STATS_FILE" ]; then
    cat > "$STATS_FILE" << 'STATS_EOF'
{
  "start_time": "PLACEHOLDER_TIME",
  "blocks_found": 0,
  "last_block_time": "",
  "last_block_hash": "",
  "local_height": 0,
  "network_height": 0,
  "last_update": ""
}
STATS_EOF
    sed -i "s/PLACEHOLDER_TIME/$(date '+%Y-%m-%d %H:%M:%S')/g" "$STATS_FILE"
fi

# 创建爆块日志文件
touch "$BLOCKS_FOUND_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 区块监控已启动" >> "$SCRIPT_DIR/monitor.log"

while true; do
    sleep 60  # 每分钟检查一次

    # 查找日志文件
    LOG_FILE=""
    if [ -f "$SCRIPT_DIR/miner.log" ]; then
        LOG_FILE="$SCRIPT_DIR/miner.log"
    elif [ -f "$SCRIPT_DIR/miner1.log" ]; then
        LOG_FILE="$SCRIPT_DIR/miner1.log"
    fi

    if [ -z "$LOG_FILE" ]; then
        continue
    fi

    # 提取本地区块高度
    LOCAL_HEIGHT=""
    tip_block=$(tail -500 "$LOG_FILE" | grep -E "tip=0x.*h=[0-9]+" | tail -1)
    if [ -n "$tip_block" ]; then
        LOCAL_HEIGHT=$(echo "$tip_block" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
    fi

    # 如果找不到，尝试其他格式
    if [ -z "$LOCAL_HEIGHT" ]; then
        LOCAL_HEIGHT=$(tail -500 "$LOG_FILE" | grep -oE "\(height=[0-9]+\)" | grep -oE "[0-9]+" | tail -1)
    fi

    # 获取全网高度（通过 RPC）
    NETWORK_HEIGHT=""
    if command -v curl &> /dev/null; then
        RPC_RESPONSE=$(curl -s -X POST http://localhost:8789 \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"cs_getBlockNumber","params":[],"id":1}' 2>/dev/null)

        if [ -n "$RPC_RESPONSE" ]; then
            # 提取十六进制结果并转换为十进制
            HEX_HEIGHT=$(echo "$RPC_RESPONSE" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
            if [ -n "$HEX_HEIGHT" ]; then
                NETWORK_HEIGHT=$((HEX_HEIGHT))
            fi
        fi
    fi

    # 检查是否爆块（检测到 mined 或 sealed block 等关键词）
    NEW_BLOCKS=$(tail -100 "$LOG_FILE" | grep -iE "mined block|sealed block|found block|block mined" || true)

    if [ -n "$NEW_BLOCKS" ]; then
        # 提取新爆块信息
        while IFS= read -r line; do
            BLOCK_HASH=$(echo "$line" | grep -oE "0x[0-9a-fA-F]{64}" | head -1)
            BLOCK_HEIGHT=$(echo "$line" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" || echo "$line" | grep -oE "height=[0-9]+" | grep -oE "[0-9]+" || echo "unknown")

            # 检查是否已记录过这个区块
            if [ -n "$BLOCK_HASH" ] && ! grep -q "$BLOCK_HASH" "$BLOCKS_FOUND_FILE" 2>/dev/null; then
                TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
                echo "$TIMESTAMP | 高度: $BLOCK_HEIGHT | 哈希: $BLOCK_HASH" >> "$BLOCKS_FOUND_FILE"

                # 更新统计
                BLOCKS_COUNT=$(wc -l < "$BLOCKS_FOUND_FILE")
                sed -i "s/\"blocks_found\": [0-9]*/\"blocks_found\": $BLOCKS_COUNT/g" "$STATS_FILE"
                sed -i "s/\"last_block_time\": \".*\"/\"last_block_time\": \"$TIMESTAMP\"/g" "$STATS_FILE"
                sed -i "s/\"last_block_hash\": \".*\"/\"last_block_hash\": \"$BLOCK_HASH\"/g" "$STATS_FILE"
            fi
        done <<< "$NEW_BLOCKS"
    fi

    # 更新统计文件
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    if [ -n "$LOCAL_HEIGHT" ]; then
        sed -i "s/\"local_height\": [0-9]*/\"local_height\": $LOCAL_HEIGHT/g" "$STATS_FILE"
    fi
    if [ -n "$NETWORK_HEIGHT" ]; then
        sed -i "s/\"network_height\": [0-9]*/\"network_height\": $NETWORK_HEIGHT/g" "$STATS_FILE"
    fi
    sed -i "s/\"last_update\": \".*\"/\"last_update\": \"$CURRENT_TIME\"/g" "$STATS_FILE"

    # 在日志中输出信息
    if [ -n "$LOCAL_HEIGHT" ] && [ -n "$NETWORK_HEIGHT" ]; then
        SYNC_DIFF=$((NETWORK_HEIGHT - LOCAL_HEIGHT))
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 本地高度: $LOCAL_HEIGHT | 全网高度: $NETWORK_HEIGHT | 差距: $SYNC_DIFF 区块" >> "$SCRIPT_DIR/monitor.log"
    fi
done
EOF

chmod +x block-monitor.sh

# 创建日志清理脚本
cat > log-cleaner.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 日志大小限制（MB）
MAX_LOG_SIZE=100

while true; do
    # 等待30分钟
    sleep 1800

    # 检查并清理所有日志文件
    for log_file in miner*.log; do
        if [ -f "$log_file" ]; then
            # 获取文件大小（MB）
            file_size=$(du -m "$log_file" | cut -f1)

            if [ "$file_size" -gt "$MAX_LOG_SIZE" ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - 清理日志文件: $log_file (大小: ${file_size}MB)"

                # 保留最后1000行，删除其余
                tail -n 1000 "$log_file" > "${log_file}.tmp"
                mv "${log_file}.tmp" "$log_file"

                echo "$(date '+%Y-%m-%d %H:%M:%S') - 清理完成"
            fi
        fi
    done
done
EOF

chmod +x log-cleaner.sh

echo ""
echo -e "${GREEN}=========================================="
echo "安装完成！"
echo "==========================================${NC}"
echo ""
echo "目录: $INSTALL_DIR"
echo ""
echo "启动方式："
echo ""
echo "1. 单显卡："
echo "   cd $INSTALL_DIR"
echo "   ./start-mining.sh <钱包地址>"
echo ""
echo "2. 多显卡："
echo "   cd $INSTALL_DIR"
echo "   ./start-multi-gpu.sh <钱包地址> 4"
echo ""
echo "3. 停止："
echo "   cd $INSTALL_DIR"
echo "   ./stop-mining.sh"
echo ""
echo "=========================================="
echo ""
echo -e "${YELLOW}提示: 所有脚本自动后台运行，关闭SSH不会终止${NC}"
echo ""
echo -e "${YELLOW}注意：首次启动需要同步区块链，可能需要一些时间${NC}"
echo ""
echo "硬件要求："
echo "  - CPU: 4+ 核心"
echo "  - 内存: 8-16 GB"
echo "  - 存储: SSD"
echo ""
