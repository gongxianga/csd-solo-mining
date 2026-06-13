#!/bin/bash

# CSD Solo 挖矿管理菜单
# 一键下载运行: curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o menu.sh && chmod +x menu.sh && ./menu.sh

# 版本号
MENU_VERSION="v2.2.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 安装目录
INSTALL_DIR="$HOME/csd-solo-miner"

# 检查是否已安装
check_installation() {
    if [ -f "$INSTALL_DIR/target/release/csd" ]; then
        return 0
    else
        return 1
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
    echo "  CSD Solo 挖矿管理菜单 ${MENU_VERSION}"
    echo -e "==========================================${NC}"
    echo ""

    if check_installation; then
        echo -e "安装状态: ${GREEN}已安装${NC}"
        echo "安装目录: $INSTALL_DIR"
    else
        echo -e "安装状态: ${YELLOW}未安装${NC}"
    fi

    echo -n "运行状态: "
    check_status

    # 显示系统资源状态
    local fd_limit=$(ulimit -n)
    local swap_count=$(swapon -s 2>/dev/null | wc -l)
    if [ "$fd_limit" -ge 65536 ] && [ "$swap_count" -gt 1 ]; then
        echo -e "系统资源: ${GREEN}正常${NC}"
    else
        echo -e "系统资源: ${RED}需要优化 → 选项 o${NC}"
    fi
    echo ""
    echo "1. 安装/重新安装 CSD 挖矿程序"
    echo "2. 启动单显卡挖矿"
    echo "3. 启动多显卡挖矿"
    echo "4. 停止挖矿"
    echo "5. 查看实时日志 (Ctrl+C 退出)"
    echo "6. 查看最近日志 (最后50行)"
    echo "7. 查看运行状态"
    echo "8. 查看爆块统计"
    echo "9. 重启挖矿"
    echo "o. 系统优化（修复文件描述符/Swap/网络）"
    echo "d. 诊断信息（查看监控状态）"
    echo "u. 更新菜单脚本"
    echo "x. 卸载程序"
    echo "0. 退出"
    echo ""
    echo -n "请选择: "
}

# 安装程序
install_program() {
    echo ""
    echo -e "${BLUE}========== 安装 CSD 挖矿程序 ==========${NC}"
    echo ""

    if check_installation; then
        echo -e "${YELLOW}检测到已安装，是否重新安装? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" != "y" ]; then
            return
        fi

        # 停止运行中的进程
        if pgrep -f "csd node" > /dev/null; then
            echo "停止运行中的挖矿进程..."
            pkill -f 'csd node'
            sleep 2
        fi

        echo "删除旧版本..."
        rm -rf "$INSTALL_DIR"
    fi

    echo -e "${GREEN}开始安装...${NC}"
    echo ""

    # 下载并运行安装脚本
    if command -v curl &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/install.sh | bash
    elif command -v wget &> /dev/null; then
        wget -qO- https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/install.sh | bash
    else
        echo -e "${RED}错误: 未找到 curl 或 wget${NC}"
        echo "请安装 curl 或 wget 后重试"
        sleep 3
        return
    fi

    echo ""
    echo -e "${GREEN}安装完成！${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 启动单显卡
start_single() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装，请先选择 1 安装程序${NC}"
        sleep 2
        return
    fi

    echo -n "请输入钱包地址: "
    read wallet

    if [ -z "$wallet" ]; then
        echo -e "${RED}错误: 钱包地址不能为空${NC}"
        sleep 2
        return
    fi

    if pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}检测到挖矿进程正在运行，是否停止并重启? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" = "y" ]; then
            bash "$INSTALL_DIR/stop-mining.sh"
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动单显卡挖矿...${NC}"

    if [ ! -f "$INSTALL_DIR/start-mining.sh" ]; then
        echo -e "${RED}错误: 启动脚本不存在${NC}"
        echo "请重新安装程序"
        sleep 2
        return
    fi

    cd "$INSTALL_DIR" && bash "$INSTALL_DIR/start-mining.sh" "$wallet"
    sleep 2
    echo ""
    echo -e "${GREEN}启动完成！${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 启动多显卡
start_multi() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装，请先选择 1 安装程序${NC}"
        sleep 2
        return
    fi

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

    if pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}检测到挖矿进程正在运行，是否停止并重启? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" = "y" ]; then
            bash "$INSTALL_DIR/stop-mining.sh"
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动 $gpu_count 显卡挖矿...${NC}"

    if [ ! -f "$INSTALL_DIR/start-multi-gpu.sh" ]; then
        echo -e "${RED}错误: 启动脚本不存在${NC}"
        echo "请重新安装程序"
        sleep 2
        return
    fi

    cd "$INSTALL_DIR" && bash "$INSTALL_DIR/start-multi-gpu.sh" "$wallet" "$gpu_count"
    sleep 2
    echo ""
    echo -e "${GREEN}启动完成！${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 停止挖矿
stop_mining() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    if ! pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}没有运行中的挖矿进程${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认停止挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在停止挖矿...${NC}"
        bash "$INSTALL_DIR/stop-mining.sh"
        sleep 2
        echo -e "${GREEN}已停止！${NC}"
    fi

    echo "按任意键返回菜单..."
    read -n 1
}

# 查看日志
view_logs() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    local log_file=""

    if [ -f "$INSTALL_DIR/miner.log" ]; then
        log_file="$INSTALL_DIR/miner.log"
        echo -e "${GREEN}单显卡日志${NC}"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        log_file="$INSTALL_DIR/miner1.log"
        echo -e "${GREEN}多显卡日志 - 显卡1${NC}"
    else
        echo -e "${RED}未找到日志文件${NC}"
        echo "目录: $INSTALL_DIR"
        sleep 2
        return
    fi

    echo "文件: $log_file"
    echo ""
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}提示：按 Ctrl+C 可以退出日志查看${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    echo ""
    sleep 1

    # 使用 trap 捕获 Ctrl+C，避免退出整个脚本
    (
        trap 'echo -e "\n${GREEN}退出日志查看...${NC}"; exit 0' INT
        tail -f "$log_file"
    )

    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}

# 查看最近日志
view_recent_logs() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    local log_file=""

    if [ -f "$INSTALL_DIR/miner.log" ]; then
        log_file="$INSTALL_DIR/miner.log"
        echo -e "${GREEN}========== 单显卡日志（最后50行）==========${NC}"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        log_file="$INSTALL_DIR/miner1.log"
        echo -e "${GREEN}========== 多显卡日志 - 显卡1（最后50行）==========${NC}"
    else
        echo -e "${RED}未找到日志文件${NC}"
        echo "目录: $INSTALL_DIR"
        sleep 2
        return
    fi

    echo "文件: $log_file"
    echo ""

    tail -n 50 "$log_file"

    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}

# 查看状态
view_status() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "         运行状态监控"
    echo -e "==========================================${NC}"

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    echo -e "${GREEN}[安装信息]${NC}"
    echo "安装目录: $INSTALL_DIR"
    echo ""

    if ! pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}当前没有运行中的挖矿进程${NC}"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    echo -e "${GREEN}[进程信息]${NC}"
    local process_count=$(pgrep -f "csd node" | wc -l)
    echo "运行实例数: $process_count"
    ps aux | grep "csd node" | grep -v grep | awk '{printf "  PID: %s | CPU: %s%% | MEM: %s%% | 运行时间: %s\n", $2, $3, $4, $10}'

    # 检查日志清理进程
    if pgrep -f "log-cleaner.sh" > /dev/null; then
        echo -e "日志清理: ${GREEN}运行中${NC} (每30分钟清理一次)"
    else
        echo -e "日志清理: ${YELLOW}未运行${NC}"
    fi

    # 检查区块监控进程
    if pgrep -f "block-monitor.sh" > /dev/null; then
        echo -e "区块监控: ${GREEN}运行中${NC}"
    else
        echo -e "区块监控: ${YELLOW}未运行${NC}"
    fi
    echo ""

    # 从日志中提取网络和同步信息
    local log_file=""
    if [ -f "$INSTALL_DIR/miner.log" ]; then
        log_file="$INSTALL_DIR/miner.log"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        log_file="$INSTALL_DIR/miner1.log"
    fi

    if [ -n "$log_file" ]; then
        echo -e "${GREEN}[网络状态]${NC}"

        # 检查 RPC 端口是否开启
        if netstat -tln 2>/dev/null | grep -q ":8789 " || ss -tln 2>/dev/null | grep -q ":8789 "; then
            echo -e "RPC 端口: ${GREEN}正常 (8789)${NC}"
        else
            echo -e "RPC 端口: ${YELLOW}检测中...${NC}"
        fi

        # 获取本地区块高度
        local block_num=""

        # 方法1: 通过本地 RPC 接口获取（最准确）
        if command -v curl &> /dev/null; then
            for method in "eth_blockNumber" "cs_blockNumber" "substrate_blockNumber"; do
                local rpc_response=$(curl -s -m 1 -X POST http://localhost:8789 \
                    -H "Content-Type: application/json" \
                    -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}" 2>/dev/null)

                if [ -n "$rpc_response" ] && echo "$rpc_response" | grep -q "result"; then
                    local hex_height=$(echo "$rpc_response" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
                    if [ -n "$hex_height" ]; then
                        block_num=$((hex_height))
                        break
                    fi
                fi
            done
        fi

        # 方法2: 从日志提取 [tip] 行
        if [ -z "$block_num" ] || [ "$block_num" -eq 0 ] 2>/dev/null; then
            local tip_line=$(tail -500 "$log_file" | grep -E "\[tip\].*h=[0-9]+" | tail -1)
            if [ -n "$tip_line" ]; then
                block_num=$(echo "$tip_line" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
            fi
        fi

        # 方法3: 从 tip= 格式提取
        if [ -z "$block_num" ] || [ "$block_num" -eq 0 ] 2>/dev/null; then
            local tip_block=$(tail -500 "$log_file" | grep -E "tip=0x[0-9a-fA-F]+.*h=[0-9]+" | tail -1)
            if [ -n "$tip_block" ]; then
                block_num=$(echo "$tip_block" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
            fi
        fi

        # 方法4: 从 now tip= 提取
        if [ -z "$block_num" ] || [ "$block_num" -eq 0 ] 2>/dev/null; then
            local now_tip=$(tail -500 "$log_file" | grep "now tip=" | tail -1)
            if [ -n "$now_tip" ]; then
                block_num=$(echo "$now_tip" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
            fi
        fi

        if [ -n "$block_num" ] && [ "$block_num" -gt 0 ] 2>/dev/null; then
            echo -e "本地区块: ${GREEN}#$block_num${NC}"

            # 获取全网高度（优先使用官方 API）
            local network_height=""

            # 方法1: 直接从官方 API 获取（最准确，最优先）
            if command -v curl &> /dev/null; then
                local api_height=$(curl -s -m 2 "https://cairn-substrate.com/explorer/api/blocks/tip/height" 2>/dev/null | grep -oE '^[0-9]+$')
                if [ -n "$api_height" ] && [ "$api_height" -gt 0 ] 2>/dev/null; then
                    network_height=$api_height
                fi
            fi

            # 方法2: 从统计文件读取（如果监控程序在运行）
            if [ -z "$network_height" ] || [ "$network_height" -eq 0 ] 2>/dev/null; then
                if [ -f "$INSTALL_DIR/mining-stats.txt" ]; then
                    local stat_height=$(grep -oE '"network_height": [0-9]+' "$INSTALL_DIR/mining-stats.txt" | grep -oE '[0-9]+')
                    # 只有当统计高度大于本地高度时才使用（避免使用旧数据）
                    if [ -n "$stat_height" ] && [ "$stat_height" -gt "$block_num" ] 2>/dev/null; then
                        network_height=$stat_height
                    fi
                fi
            fi

            # 显示全网高度和同步状态
            if [ -n "$network_height" ] && [ "$network_height" -gt 0 ] 2>/dev/null; then
                echo -e "全网高度: ${GREEN}#$network_height${NC}"

                # 计算同步差距
                local sync_diff=$((network_height - block_num))

                # 检查是否反常（本地高度大于全网高度）
                if [ "$sync_diff" -lt 0 ]; then
                    sync_diff=$((block_num - network_height))
                    echo -e "同步状态: ${YELLOW}本地高度超前 $sync_diff 区块${NC}"
                    echo "提示: 可能是全网高度数据延迟，或者你的节点在不同分支"
                elif [ "$sync_diff" -le 10 ]; then
                    echo -e "同步差距: ${GREEN}$sync_diff 个区块${NC} (已同步)"
                elif [ "$sync_diff" -le 100 ]; then
                    echo -e "同步差距: ${YELLOW}$sync_diff 个区块${NC} (接近同步)"
                else
                    echo -e "同步差距: ${YELLOW}$sync_diff 个区块${NC} (同步中)"
                fi
            else
                echo -e "全网高度: ${YELLOW}检测中...${NC}"
                echo "提示: API 获取失败，请检查网络连接"
            fi

            # 显示区块工作量（如果有）
            if [ -n "$tip_block" ]; then
                local work=$(echo "$tip_block" | grep -oE "w=[0-9]+" | grep -oE "[0-9]+" | tail -1)
                if [ -n "$work" ]; then
                    echo "区块工作量: $work"
                fi
            fi
        else
            # 如果找不到明确的区块号，显示正在同步中
            local sync_count=$(tail -100 "$log_file" | grep -c "sync\|gossip\|request")
            if [ "$sync_count" -gt 0 ]; then
                echo -e "区块高度: ${YELLOW}同步中...${NC} (正在下载区块)"
            else
                echo -e "区块高度: ${YELLOW}未检测到${NC}"
            fi
        fi

        # 提取已知节点数 (known_peers 数字 -> 数字)
        local peer_line=$(tail -200 "$log_file" | grep "known_peers" | tail -1)
        if [ -n "$peer_line" ]; then
            local peer_count=$(echo "$peer_line" | grep -oE "known_peers [0-9]+ -> [0-9]+" | grep -oE "[0-9]+$")
            if [ -n "$peer_count" ] && [ "$peer_count" -gt 0 ] 2>/dev/null; then
                echo -e "已知节点数: ${GREEN}$peer_count${NC}"
            fi
        fi

        # 检查同步状态和活动
        local recent_logs=$(tail -50 "$log_file")
        local sync_count=$(echo "$recent_logs" | grep -c "\[sync\]")
        local reorg_count=$(echo "$recent_logs" | grep -c "\[reorg\]")
        local got_headers=$(echo "$recent_logs" | grep -c "got headers")
        local got_block=$(echo "$recent_logs" | grep -c "got block")

        if [ "$sync_count" -gt 0 ] || [ "$got_headers" -gt 0 ]; then
            echo -e "同步状态: ${YELLOW}同步中${NC}"

            # 显示最近收到的头部和区块
            if [ "$got_headers" -gt 0 ]; then
                echo "  - 最近收到 headers: $got_headers 次"
            fi
            if [ "$got_block" -gt 0 ]; then
                echo "  - 最近收到 blocks: $got_block 次"
            fi
            if [ "$reorg_count" -gt 0 ]; then
                echo -e "  - ${YELLOW}检测到链重组: $reorg_count 次${NC}"
            fi
        else
            echo -e "同步状态: ${GREEN}已同步${NC}"
        fi

        echo ""
        echo -e "${GREEN}[最近日志]${NC} (最后10行)"
        tail -10 "$log_file" | sed 's/^/  /'
    else
        echo -e "${YELLOW}未找到日志文件，无法显示网络状态${NC}"
    fi

    echo ""
    echo -e "${GREEN}[存储信息]${NC}"
    echo "日志文件:"
    ls -lh "$INSTALL_DIR"/*.log 2>/dev/null | awk '{printf "  %s  %s\n", $9, $5}' || echo "  无日志文件"
    echo ""
    echo "数据目录:"
    du -sh "$INSTALL_DIR"/cs*.db 2>/dev/null | awk '{printf "  %s  (%s)\n", $2, $1}' || echo "  无数据目录"

    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 查看爆块统计
view_blocks_stats() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "         爆块统计"
    echo -e "==========================================${NC}"

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    # 统计文件路径
    STATS_FILE="$INSTALL_DIR/mining-stats.txt"
    BLOCKS_FILE="$INSTALL_DIR/blocks-found.log"

    if [ ! -f "$STATS_FILE" ]; then
        echo -e "${YELLOW}未找到统计数据${NC}"
        echo "区块监控程序可能未启动或刚启动不久"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    echo -e "${GREEN}[挖矿统计]${NC}"

    # 提取统计信息
    start_time=$(grep -oE '"start_time": "[^"]*"' "$STATS_FILE" | cut -d'"' -f4)
    blocks_found=$(grep -oE '"blocks_found": [0-9]+' "$STATS_FILE" | grep -oE '[0-9]+')
    last_block_time=$(grep -oE '"last_block_time": "[^"]*"' "$STATS_FILE" | cut -d'"' -f4)
    last_block_hash=$(grep -oE '"last_block_hash": "[^"]*"' "$STATS_FILE" | cut -d'"' -f4)
    local_height=$(grep -oE '"local_height": [0-9]+' "$STATS_FILE" | grep -oE '[0-9]+')
    network_height=$(grep -oE '"network_height": [0-9]+' "$STATS_FILE" | grep -oE '[0-9]+')
    last_update=$(grep -oE '"last_update": "[^"]*"' "$STATS_FILE" | cut -d'"' -f4)

    echo "开始时间: $start_time"
    echo "最后更新: $last_update"
    echo ""

    echo -e "${GREEN}[区块高度]${NC}"
    if [ -n "$local_height" ] && [ "$local_height" -gt 0 ] 2>/dev/null; then
        echo "本地高度: #$local_height"
    else
        echo "本地高度: 未同步"
    fi

    # 优先从 API 获取全网高度（最准确）
    if command -v curl &> /dev/null; then
        api_height=$(curl -s -m 2 "https://cairn-substrate.com/explorer/api/blocks/tip/height" 2>/dev/null | grep -oE '^[0-9]+$')
        if [ -n "$api_height" ] && [ "$api_height" -gt 0 ] 2>/dev/null; then
            # API 获取成功，使用 API 高度
            network_height=$api_height
        fi
    fi

    # 如果 API 失败，从统计文件读取（但要验证合理性）
    if [ -z "$network_height" ] || [ "$network_height" -eq 0 ] 2>/dev/null; then
        stat_height=$(grep -oE '"network_height": [0-9]+' "$STATS_FILE" | grep -oE '[0-9]+')
        # 只有当统计高度明显大于本地高度时才使用
        if [ -n "$stat_height" ] && [ -n "$local_height" ]; then
            if [ "$stat_height" -ge "$local_height" ] 2>/dev/null; then
                network_height=$stat_height
            fi
        elif [ -n "$stat_height" ] && [ -z "$local_height" ]; then
            network_height=$stat_height
        fi
    fi

    if [ -n "$network_height" ] && [ "$network_height" -gt 0 ] 2>/dev/null; then
        echo "全网高度: #$network_height"

        if [ -n "$local_height" ] && [ "$local_height" -gt 0 ] 2>/dev/null; then
            sync_diff=$((network_height - local_height))

            if [ "$sync_diff" -lt 0 ]; then
                # 本地高度超过全网高度
                sync_diff=$((local_height - network_height))
                echo -e "同步状态: ${YELLOW}本地超前 $sync_diff 区块${NC}"
            else
                # 正常情况
                sync_percent=$((local_height * 100 / network_height))
                if [ "$sync_diff" -le 10 ]; then
                    echo -e "同步进度: ${GREEN}${sync_percent}%${NC} (已同步，差距 $sync_diff 区块)"
                else
                    echo -e "同步进度: ${YELLOW}${sync_percent}%${NC} (同步中，差距 $sync_diff 区块)"
                fi
            fi
        fi
    else
        echo -e "全网高度: ${YELLOW}获取失败${NC}"
        echo "提示: 请检查网络连接或稍后重试"
    fi
    echo ""

    echo -e "${GREEN}[爆块记录]${NC}"
    if [ -n "$blocks_found" ] && [ "$blocks_found" -gt 0 ] 2>/dev/null; then
        echo -e "累计爆块: ${GREEN}$blocks_found 个${NC}"

        if [ -n "$last_block_time" ]; then
            echo "最后爆块: $last_block_time"
        fi
        if [ -n "$last_block_hash" ]; then
            echo "区块哈希: ${last_block_hash:0:20}...${last_block_hash: -20}"
        fi

        # 计算运行时间和爆块率
        if [ -n "$start_time" ]; then
            start_epoch=$(date -d "$start_time" +%s 2>/dev/null || date +%s)
            now_epoch=$(date +%s)
            run_hours=$(( (now_epoch - start_epoch) / 3600 ))

            if [ "$run_hours" -gt 0 ]; then
                blocks_per_hour=$(echo "scale=2; $blocks_found / $run_hours" | bc 2>/dev/null || echo "0")
                echo "运行时长: ${run_hours} 小时"
                echo "爆块速率: ${blocks_per_hour} 块/小时"
            fi
        fi

        echo ""
        echo -e "${GREEN}[爆块详情]${NC}"
        if [ -f "$BLOCKS_FILE" ] && [ -s "$BLOCKS_FILE" ]; then
            echo "最近10个爆块："
            tail -10 "$BLOCKS_FILE" | nl -w2 -s'. '
        else
            echo "暂无爆块记录"
        fi
    else
        echo -e "${YELLOW}暂无爆块${NC}"
        echo "继续运行，耐心等待..."
    fi

    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 诊断信息
diagnostic_info() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "         诊断信息"
    echo -e "==========================================${NC}"

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    echo -e "${GREEN}[进程状态]${NC}"
    if pgrep -f "csd node" > /dev/null; then
        echo -e "挖矿进程: ${GREEN}运行中${NC}"
        pgrep -f "csd node" | head -3 | while read pid; do
            echo "  PID: $pid"
        done
    else
        echo -e "挖矿进程: ${RED}未运行${NC}"
    fi

    if pgrep -f "block-monitor.sh" > /dev/null; then
        echo -e "监控进程: ${GREEN}运行中${NC}"
        echo "  PID: $(pgrep -f "block-monitor.sh")"
    else
        echo -e "监控进程: ${RED}未运行${NC}"
    fi
    echo ""

    echo -e "${GREEN}[监控文件]${NC}"
    if [ -f "$INSTALL_DIR/mining-stats.txt" ]; then
        echo "统计文件: 存在"
        echo "内容:"
        cat "$INSTALL_DIR/mining-stats.txt" | sed 's/^/  /'
    else
        echo -e "统计文件: ${RED}不存在${NC}"
    fi
    echo ""

    if [ -f "$INSTALL_DIR/monitor.log" ]; then
        echo "监控日志: 存在"
        echo "最近5行:"
        tail -5 "$INSTALL_DIR/monitor.log" | sed 's/^/  /'
    else
        echo -e "监控日志: ${RED}不存在${NC}"
    fi
    echo ""

    echo -e "${GREEN}[本地 RPC 接口测试]${NC}"
    if command -v curl &> /dev/null; then
        echo "测试本地节点 RPC (localhost:8789)..."

        # 测试多个方法
        for method in "eth_blockNumber" "cs_blockNumber" "substrate_blockNumber"; do
            echo -n "  测试 $method: "
            rpc_result=$(curl -s -m 1 -X POST http://localhost:8789 \
                -H "Content-Type: application/json" \
                -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}" 2>/dev/null)

            if [ -n "$rpc_result" ]; then
                if echo "$rpc_result" | grep -q "result"; then
                    hex_val=$(echo "$rpc_result" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
                    if [ -n "$hex_val" ]; then
                        dec_val=$((hex_val))
                        echo -e "${GREEN}成功 (本地高度: $dec_val)${NC}"
                    else
                        echo -e "${YELLOW}返回但无高度数据${NC}"
                    fi
                else
                    echo -e "${RED}失败: $(echo "$rpc_result" | head -c 50)${NC}"
                fi
            else
                echo -e "${RED}无响应${NC}"
            fi
        done
    else
        echo -e "${RED}curl 未安装${NC}"
    fi
    echo ""

    echo -e "${GREEN}[全网高度 API 测试]${NC}"
    if command -v curl &> /dev/null; then
        echo "测试官方 API (cairn-substrate.com)..."

        echo -n "  测试 /blocks/tip/height: "
        api_result=$(curl -s -m 3 "https://cairn-substrate.com/explorer/api/blocks/tip/height" 2>/dev/null)
        if [ -n "$api_result" ]; then
            api_height=$(echo "$api_result" | grep -oE '^[0-9]+$')
            if [ -n "$api_height" ] && [ "$api_height" -gt 0 ] 2>/dev/null; then
                echo -e "${GREEN}成功 (全网高度: $api_height)${NC}"
            else
                echo -e "${RED}返回数据格式错误: $api_result${NC}"
            fi
        else
            echo -e "${RED}无响应或超时${NC}"
        fi

        echo -n "  测试 /health: "
        health_result=$(curl -s -m 3 "https://cairn-substrate.com/explorer/api/health" 2>/dev/null)
        if [ -n "$health_result" ]; then
            health_height=$(echo "$health_result" | grep -oE '"indexed_height":[0-9]+' | grep -oE '[0-9]+')
            if [ -n "$health_height" ] && [ "$health_height" -gt 0 ] 2>/dev/null; then
                echo -e "${GREEN}成功 (索引高度: $health_height)${NC}"
            else
                echo -e "${YELLOW}返回但无高度数据${NC}"
            fi
        else
            echo -e "${RED}无响应或超时${NC}"
        fi
    else
        echo -e "${RED}curl 未安装${NC}"
    fi
    echo ""

    echo -e "${GREEN}[日志分析]${NC}"
    local log_file=""
    if [ -f "$INSTALL_DIR/miner.log" ]; then
        log_file="$INSTALL_DIR/miner.log"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        log_file="$INSTALL_DIR/miner1.log"
    fi

    if [ -n "$log_file" ]; then
        echo "日志文件: $log_file"
        echo "文件大小: $(du -h "$log_file" | cut -f1)"

        # 检查日志中是否有区块高度信息
        local tip_count=$(tail -500 "$log_file" | grep -c "\[tip\]")
        local tip_eq_count=$(tail -500 "$log_file" | grep -c "tip=")
        local height_count=$(tail -500 "$log_file" | grep -c "height=")
        local sync_count=$(tail -500 "$log_file" | grep -c "\[sync\]")

        echo ""
        echo "最近500行日志统计:"
        echo "  - 包含 '[tip]' 的行: $tip_count"
        echo "  - 包含 'tip=' 的行: $tip_eq_count"
        echo "  - 包含 'height=' 的行: $height_count"
        echo "  - 包含 '[sync]' 的行: $sync_count"

        # 提取一些示例行
        echo ""
        echo "最近的 [tip] 记录:"
        tail -500 "$log_file" | grep "\[tip\]" | tail -3 | sed 's/^/  /' || echo "  (无)"

        echo ""
        echo "最近的 tip= 记录:"
        tail -500 "$log_file" | grep "tip=" | tail -3 | sed 's/^/  /' || echo "  (无)"

        echo ""
        echo "最近的 now tip= 记录:"
        tail -500 "$log_file" | grep "now tip=" | tail -3 | sed 's/^/  /' || echo "  (无)"
    else
        echo -e "${RED}未找到日志文件${NC}"
    fi

    echo ""
    echo -e "${GREEN}[建议]${NC}"

    # 检查本地高度获取
    local can_get_local=false
    if [ -n "$log_file" ]; then
        local test_tip=$(tail -500 "$log_file" | grep -E "\[tip\]|tip=|now tip=" | head -1)
        if [ -n "$test_tip" ]; then
            can_get_local=true
        fi
    fi

    if ! pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}挖矿进程未运行，请先启动挖矿${NC}"
    elif [ "$can_get_local" = false ]; then
        echo -e "${YELLOW}日志中无法找到本地高度信息，可能原因：${NC}"
        echo "  1. 节点刚启动，还未生成 tip 日志"
        echo "  2. 日志格式已更改"
        echo "  3. 建议：等待2-3分钟后重新查看"
        echo "  4. 或尝试：tail -f $log_file | grep tip"
    elif ! pgrep -f "block-monitor.sh" > /dev/null; then
        echo -e "${YELLOW}监控进程未运行，请尝试重启挖矿以启动监控${NC}"
    elif [ ! -f "$INSTALL_DIR/mining-stats.txt" ]; then
        echo -e "${YELLOW}统计文件不存在，监控程序可能刚启动，请等待1-2分钟${NC}"
    else
        local local_h=$(grep -oE '"local_height": [0-9]+' "$INSTALL_DIR/mining-stats.txt" | grep -oE '[0-9]+')
        local network_h=$(grep -oE '"network_height": [0-9]+' "$INSTALL_DIR/mining-stats.txt" | grep -oE '[0-9]+')

        if [ -z "$local_h" ] || [ "$local_h" -eq 0 ] 2>/dev/null; then
            echo -e "${YELLOW}本地高度为0或未获取，建议：${NC}"
            echo "  1. 检查上方 '本地 RPC 接口测试' 结果"
            echo "  2. 查看日志示例中是否有 h= 数字"
            echo "  3. 等待节点完成初始化（2-5分钟）"
        elif [ -z "$network_h" ] || [ "$network_h" -eq 0 ] 2>/dev/null; then
            echo -e "${YELLOW}全网高度未获取，但本地高度正常: $local_h${NC}"
            echo "  1. 检查上方 '全网高度 API 测试' 结果"
            echo "  2. 确认网络连接正常"
            echo "  3. 可能是 API 暂时不可用"
        elif [ "$local_h" -eq "$network_h" ] 2>/dev/null; then
            echo -e "${YELLOW}本地高度和全网高度相同: $local_h${NC}"
            echo "  可能原因："
            echo "  1. 已完全同步（正常情况）"
            echo "  2. 全网高度获取失败，被设置为本地高度（异常）"
            echo "  请检查上方 '全网高度 API 测试' 是否成功"
        else
            local diff=$((network_h - local_h))
            echo -e "${GREEN}监控运行正常${NC}"
            echo "  本地高度: $local_h | 全网高度: $network_h | 差距: $diff"
        fi
    fi

    echo ""
    system_resource_check
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo "按任意键返回菜单..."
    read -n 1
}

# 重启挖矿
restart_mining() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    if ! pgrep -f "csd node" > /dev/null; then
        echo -e "${YELLOW}没有运行中的挖矿进程，请使用启动功能${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认重启挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在重启...${NC}"
        bash "$INSTALL_DIR/stop-mining.sh"
        sleep 3

        # 检测之前运行的是单显卡还是多显卡
        if [ -f "$INSTALL_DIR/miner1.log" ]; then
            echo "检测到多显卡配置，重启多显卡模式"
            start_multi
        else
            echo "检测到单显卡配置，重启单显卡模式"
            start_single
        fi
    fi
}

# 卸载程序
uninstall_program() {
    echo ""
    echo -e "${RED}========== 卸载程序 ==========${NC}"
    echo ""

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}警告: 这将删除所有数据和日志${NC}"
    echo -e "${YELLOW}确认卸载? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        # 停止进程
        if pgrep -f "csd node" > /dev/null; then
            echo "停止运行中的进程..."
            pkill -f 'csd node'
            sleep 2
        fi

        echo "删除安装目录..."
        rm -rf "$INSTALL_DIR"

        echo ""
        echo -e "${GREEN}卸载完成！${NC}"
    else
        echo "已取消"
    fi

    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}

# 更新菜单脚本
update_menu() {
    echo ""
    echo -e "${BLUE}========== 更新菜单脚本 ==========${NC}"
    echo ""

    # 获取当前脚本路径
    CURRENT_SCRIPT="$0"
    SCRIPT_NAME=$(basename "$CURRENT_SCRIPT")

    echo "当前脚本: $CURRENT_SCRIPT"
    echo ""
    echo -e "${YELLOW}确认更新到最新版本? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" != "y" ]; then
        echo "已取消"
        sleep 1
        return
    fi

    echo -e "${GREEN}正在从 GitHub 下载最新版本...${NC}"

    # 下载到临时文件
    TEMP_FILE="${CURRENT_SCRIPT}.new"

    if command -v curl &> /dev/null; then
        if curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o "$TEMP_FILE"; then
            chmod +x "$TEMP_FILE"
            mv "$TEMP_FILE" "$CURRENT_SCRIPT"
            echo ""
            echo -e "${GREEN}更新成功！重新启动菜单...${NC}"
            sleep 2
            exec "$CURRENT_SCRIPT"
        else
            echo -e "${RED}下载失败，请检查网络连接${NC}"
            rm -f "$TEMP_FILE"
        fi
    elif command -v wget &> /dev/null; then
        if wget -q https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -O "$TEMP_FILE"; then
            chmod +x "$TEMP_FILE"
            mv "$TEMP_FILE" "$CURRENT_SCRIPT"
            echo ""
            echo -e "${GREEN}更新成功！重新启动菜单...${NC}"
            sleep 2
            exec "$CURRENT_SCRIPT"
        else
            echo -e "${RED}下载失败，请检查网络连接${NC}"
            rm -f "$TEMP_FILE"
        fi
    else
        echo -e "${RED}错误: 未找到 curl 或 wget${NC}"
    fi

    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}


# ==========================================
# 系统优化功能（新增）
# ==========================================

# 系统优化
system_optimize() {
    echo ""
    echo -e "${BLUE}========== 系统优化 ==========${NC}"
    echo ""

    echo -e "${YELLOW}当前系统状态：${NC}"
    local cur_fd=$(ulimit -n)
    local has_swap=$(swapon -s 2>/dev/null | wc -l)
    local tcp_backlog=$(cat /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null)

    if [ "$cur_fd" -ge 65536 ]; then
        echo -e "  文件描述符: ${GREEN}$cur_fd ✓${NC}"
    else
        echo -e "  文件描述符: ${RED}$cur_fd (建议 ≥ 65536)${NC}"
    fi

    if [ "$has_swap" -gt 1 ]; then
        echo -e "  Swap 空间: ${GREEN}已启用 ✓${NC}"
    else
        echo -e "  Swap 空间: ${RED}未启用${NC}"
    fi

    if [ "$tcp_backlog" -ge 4096 ]; then
        echo -e "  TCP SYN 队列: ${GREEN}$tcp_backlog ✓${NC}"
    else
        echo -e "  TCP SYN 队列: ${RED}$tcp_backlog (建议 ≥ 4096)${NC}"
    fi

    echo ""
    echo -e "${YELLOW}此操作需要 root 权限，将永久优化以下设置：${NC}"
    echo "  - 文件描述符限制提升至 65536"
    echo "  - 创建 4GB Swap 空间（如未存在）"
    echo "  - 优化 TCP 连接和端口参数"
    echo ""
    echo -e "${YELLOW}确认运行系统优化? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" != "y" ]; then
        echo "已取消"
        sleep 1
        return
    fi

    # 检查是否有root权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}需要 sudo 权限，请输入密码：${NC}"
        sudo bash -c "
            # 1. 文件描述符限制
            if ! grep -q 'CSD Mining' /etc/security/limits.conf; then
                cat >> /etc/security/limits.conf << 'EOF'
# CSD Mining 优化
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF
                echo '✓ 文件描述符限制已设置'
            else
                echo '✓ 文件描述符限制已存在'
            fi

            # 2. 创建 Swap
            if [ \$(swapon -s | wc -l) -le 1 ]; then
                echo '正在创建 4GB Swap...'
                dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
                grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness = 10' >> /etc/sysctl.conf
                echo '✓ Swap 空间创建完成'
            else
                echo '✓ Swap 已存在'
            fi

            # 3. 网络参数
            if ! grep -q 'CSD Mining 网络优化' /etc/sysctl.conf; then
                cat >> /etc/sysctl.conf << 'EOF'
# CSD Mining 网络优化
net.ipv4.ip_local_port_range = 10000 65535
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
EOF
                echo '✓ 网络参数已设置'
            else
                echo '✓ 网络参数已存在'
            fi

            # 4. 应用参数
            sysctl -p > /dev/null 2>&1
            echo '✓ 参数已应用'

            # 5. 环境配置
            if [ ! -f /etc/profile.d/csd-mining.sh ]; then
                echo 'ulimit -n 65536' > /etc/profile.d/csd-mining.sh
                echo '✓ 开机环境配置已创建'
            fi
        "
    else
        # 已有root权限，直接运行
        if ! grep -q 'CSD Mining' /etc/security/limits.conf; then
            printf '\n# CSD Mining 优化\n* soft nofile 65536\n* hard nofile 65536\n* soft nproc 65536\n* hard nproc 65536\nroot soft nofile 65536\nroot hard nofile 65536\n' >> /etc/security/limits.conf
            echo -e "${GREEN}✓ 文件描述符限制已设置${NC}"
        else
            echo -e "${GREEN}✓ 文件描述符限制已存在${NC}"
        fi

        if [ $(swapon -s | wc -l) -le 1 ]; then
            echo -e "${BLUE}正在创建 4GB Swap...${NC}"
            dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
            grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness = 10' >> /etc/sysctl.conf
            echo -e "${GREEN}✓ Swap 创建完成${NC}"
        else
            echo -e "${GREEN}✓ Swap 已存在${NC}"
        fi

        if ! grep -q 'CSD Mining 网络优化' /etc/sysctl.conf; then
            printf '\n# CSD Mining 网络优化\nnet.ipv4.ip_local_port_range = 10000 65535\nnet.core.somaxconn = 65535\nnet.core.netdev_max_backlog = 5000\nnet.ipv4.tcp_max_syn_backlog = 8192\nnet.ipv4.tcp_tw_reuse = 1\nnet.ipv4.tcp_fin_timeout = 15\n' >> /etc/sysctl.conf
            echo -e "${GREEN}✓ 网络参数已设置${NC}"
        else
            echo -e "${GREEN}✓ 网络参数已存在${NC}"
        fi

        sysctl -p > /dev/null 2>&1
        echo -e "${GREEN}✓ 参数已应用${NC}"

        if [ ! -f /etc/profile.d/csd-mining.sh ]; then
            echo 'ulimit -n 65536' > /etc/profile.d/csd-mining.sh
            echo -e "${GREEN}✓ 开机环境配置已创建${NC}"
        fi
    fi

    echo ""
    echo -e "${GREEN}优化完成！${NC}"
    echo -e "${RED}重要: 需要重新登录 SSH 使文件描述符限制生效${NC}"
    echo ""
    echo "按任意键返回菜单..."
    read -n 1
}

# 系统诊断（增强版，覆盖原有的 diagnostic_info 后添加资源信息）
system_resource_check() {
    echo ""
    echo -e "${GREEN}[系统资源]${NC}"

    local cur_fd=$(ulimit -n)
    local has_swap=$(swapon -s 2>/dev/null | wc -l)
    local tcp_backlog=$(cat /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null)

    if [ "$cur_fd" -ge 65536 ]; then
        echo -e "  文件描述符限制: ${GREEN}$cur_fd ✓${NC}"
    else
        echo -e "  文件描述符限制: ${RED}$cur_fd (建议运行系统优化 → 选项 o)${NC}"
    fi

    echo ""
    echo -e "${GREEN}[内存状态]${NC}"
    free -h | sed 's/^/  /'

    echo ""
    echo -e "${GREEN}[Swap 状态]${NC}"
    if [ "$has_swap" -gt 1 ]; then
        swapon -s | sed 's/^/  /'
        echo -e "  ${GREEN}✓ Swap 已启用${NC}"
    else
        echo -e "  ${RED}✗ 没有 Swap 空间（建议运行系统优化 → 选项 o）${NC}"
    fi

    echo ""
    echo -e "${GREEN}[网络参数]${NC}"
    echo "  端口范围: $(cat /proc/sys/net/ipv4/ip_local_port_range 2>/dev/null)"
    echo "  TCP SYN 队列: $tcp_backlog"
    echo "  连接队列: $(cat /proc/sys/net/core/somaxconn 2>/dev/null)"

    if [ "$tcp_backlog" -lt 4096 ]; then
        echo -e "  ${RED}✗ TCP 队列偏小，建议运行系统优化 → 选项 o${NC}"
    fi
}

# 主循环
main() {
    while true; do
        show_menu
        read choice

        case $choice in
            1) install_program ;;
            2) start_single ;;
            3) start_multi ;;
            4) stop_mining ;;
            5) view_logs ;;
            6) view_recent_logs ;;
            7) view_status ;;
            8) view_blocks_stats ;;
            9) restart_mining ;;
            o|O) system_optimize ;;
            d|D) diagnostic_info ;;
            u|U) update_menu ;;
            x|X) uninstall_program ;;
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
