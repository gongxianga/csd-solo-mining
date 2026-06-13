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

echo "已在后台启动！"
echo "查看日志: tail -f $SCRIPT_DIR/miner.log"
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
echo "所有挖矿实例已启动！"
echo "查看日志: tail -f $SCRIPT_DIR/miner1.log"
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
EOF

chmod +x stop-mining.sh

# 创建菜单管理脚本
cat > menu.sh << 'EOF'
#!/bin/bash

# 获取脚本所在目录并切换
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查必要文件
check_installation() {
    if [ ! -f "$SCRIPT_DIR/target/release/csd" ]; then
        echo -e "${RED}错误: 未找到 csd 程序${NC}"
        echo "当前目录: $SCRIPT_DIR"
        echo "请确保在正确的安装目录中运行此脚本"
        exit 1
    fi
}

# 检查进程状态
check_status() {
    if pgrep -f "csd node" > /dev/null; then
        echo -e "${GREEN}运行中${NC}"
        return 0
    else
        echo -e "${RED}未运行${NC}"
        return 1
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}=========================================="
    echo "  CSD Solo 挖矿管理菜单"
    echo -e "==========================================${NC}"
    echo -e "工作目录: ${YELLOW}$SCRIPT_DIR${NC}"
    echo ""
    echo -n "当前状态: "
    check_status
    echo ""
    echo "1. 启动单显卡挖矿"
    echo "2. 启动多显卡挖矿"
    echo "3. 停止挖矿"
    echo "4. 查看实时日志"
    echo "5. 查看运行状态"
    echo "6. 重启挖矿"
    echo "0. 退出"
    echo ""
    echo -n "请选择 [0-6]: "
}

# 启动单显卡
start_single() {
    echo ""
    echo -n "请输入钱包地址: "
    read wallet

    if [ -z "$wallet" ]; then
        echo -e "${RED}错误: 钱包地址不能为空${NC}"
        sleep 2
        return
    fi

    if check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}检测到挖矿进程正在运行，是否停止并重启? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" = "y" ]; then
            bash "$SCRIPT_DIR/stop-mining.sh"
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动单显卡挖矿...${NC}"
    bash "$SCRIPT_DIR/start-mining.sh" "$wallet"
    sleep 2
    echo ""
    echo -e "${GREEN}启动完成！${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 启动多显卡
start_multi() {
    echo ""
    echo -n "请输入钱包地址: "
    read wallet

    if [ -z "$wallet" ]; then
        echo -e "${RED}错误: 钱包地址不能为空${NC}"
        sleep 2
        return
    fi

    echo -n "请输入显卡数量 [默认4]: "
    read gpu_count
    gpu_count=${gpu_count:-4}

    if check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}检测到挖矿进程正在运行，是否停止并重启? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" = "y" ]; then
            bash "$SCRIPT_DIR/stop-mining.sh"
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动 $gpu_count 显卡挖矿...${NC}"
    bash "$SCRIPT_DIR/start-multi-gpu.sh" "$wallet" "$gpu_count"
    sleep 2
    echo ""
    echo -e "${GREEN}启动完成！${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 停止挖矿
stop_mining() {
    echo ""
    if ! check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}没有运行中的挖矿进程${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认停止挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在停止挖矿...${NC}"
        bash "$SCRIPT_DIR/stop-mining.sh"
        sleep 2
        echo -e "${GREEN}已停止！${NC}"
    fi

    echo "按任意键返回菜单..."
    read -n 1
}

# 查看日志
view_logs() {
    echo ""
    if [ -f "$SCRIPT_DIR/miner.log" ]; then
        echo -e "${GREEN}单显卡日志 (Ctrl+C 退出):${NC}"
        echo "文件: $SCRIPT_DIR/miner.log"
        echo ""
        tail -f "$SCRIPT_DIR/miner.log"
    elif [ -f "$SCRIPT_DIR/miner1.log" ]; then
        echo -e "${GREEN}多显卡日志 - 显卡1 (Ctrl+C 退出):${NC}"
        echo "文件: $SCRIPT_DIR/miner1.log"
        echo ""
        tail -f "$SCRIPT_DIR/miner1.log"
    else
        echo -e "${RED}未找到日志文件${NC}"
        echo "目录: $SCRIPT_DIR"
        sleep 2
    fi
}

# 查看状态
view_status() {
    echo ""
    echo -e "${BLUE}========== 运行状态 ==========${NC}"
    echo "工作目录: $SCRIPT_DIR"
    echo ""

    if check_status > /dev/null 2>&1; then
        echo "进程列表:"
        ps aux | grep "csd node" | grep -v grep
        echo ""
        echo "日志文件:"
        ls -lh "$SCRIPT_DIR"/*.log 2>/dev/null || echo "  无日志文件"
        echo ""
        echo "数据目录:"
        ls -lhd "$SCRIPT_DIR"/cs*.db 2>/dev/null || echo "  无数据目录"
    else
        echo -e "${YELLOW}当前没有运行中的挖矿进程${NC}"
    fi

    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}

# 重启挖矿
restart_mining() {
    echo ""
    if ! check_status > /dev/null 2>&1; then
        echo -e "${YELLOW}没有运行中的挖矿进程，请使用启动功能${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认重启挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在重启...${NC}"
        bash "$SCRIPT_DIR/stop-mining.sh"
        sleep 3

        # 检测之前运行的是单显卡还是多显卡
        if [ -f "$SCRIPT_DIR/miner1.log" ]; then
            echo "检测到多显卡配置，重启多显卡模式"
            # 需要用户重新输入钱包地址
            start_multi
        else
            echo "检测到单显卡配置，重启单显卡模式"
            start_single
        fi
    fi
}

# 主循环
main() {
    # 检查安装
    check_installation

    while true; do
        show_menu
        read choice

        case $choice in
            1) start_single ;;
            2) start_multi ;;
            3) stop_mining ;;
            4) view_logs ;;
            5) view_status ;;
            6) restart_mining ;;
            0)
                echo ""
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 启动主程序
main
EOF

chmod +x menu.sh

echo ""
echo -e "${GREEN}=========================================="
echo "安装完成！"
echo "==========================================${NC}"
echo ""
echo "目录: $INSTALL_DIR"
echo ""
echo -e "${YELLOW}快速启动（推荐）：${NC}"
echo ""
echo -e "   ${GREEN}cd $INSTALL_DIR && ./menu.sh${NC}"
echo ""
echo "菜单功能："
echo "  - 一键启动/停止挖矿"
echo "  - 自动后台运行（关闭SSH不会终止）"
echo "  - 实时查看日志和状态"
echo "  - 支持单显卡/多显卡切换"
echo ""
echo "=========================================="
echo ""
echo "手动启动方式："
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
echo "   ./stop-mining.sh"
echo ""
echo -e "${YELLOW}注意：首次启动需要同步区块链，可能需要一些时间${NC}"
echo ""
echo "硬件要求："
echo "  - CPU: 4+ 核心"
echo "  - 内存: 8-16 GB"
echo "  - 存储: SSD"
echo ""
