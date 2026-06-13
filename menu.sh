#!/bin/bash

# CSD Solo 挖矿管理菜单
# 一键下载运行: curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o menu.sh && chmod +x menu.sh && ./menu.sh

# 版本号
MENU_VERSION="v1.7.0"

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

        # 从日志提取区块高度 - CSD 特定格式
        local block_num=""
        local tip_block=""

        # 模式1: "h=数字" 格式（tip 区块高度）
        tip_block=$(tail -200 "$log_file" | grep -E "tip=0x.*h=[0-9]+" | tail -1)
        if [ -n "$tip_block" ]; then
            block_num=$(echo "$tip_block" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
        fi

        # 模式2: "(height=数字)" 格式（正在请求的区块）
        if [ -z "$block_num" ]; then
            block_num=$(tail -200 "$log_file" | grep -oE "\(height=[0-9]+\)" | grep -oE "[0-9]+" | tail -1)
        fi

        # 模式3: "height=数字" 格式
        if [ -z "$block_num" ]; then
            block_num=$(tail -200 "$log_file" | grep -oE "height=[0-9]+" | grep -oE "[0-9]+" | tail -1)
        fi

        if [ -n "$block_num" ] && [ "$block_num" -gt 0 ] 2>/dev/null; then
            echo -e "本地区块: ${GREEN}#$block_num${NC}"

            # 从统计文件读取全网高度
            local network_height=""
            if [ -f "$INSTALL_DIR/mining-stats.txt" ]; then
                network_height=$(grep -oE '"network_height": [0-9]+' "$INSTALL_DIR/mining-stats.txt" | grep -oE '[0-9]+')
            fi

            # 如果统计文件没有全网高度，尝试从日志中直接提取
            if [ -z "$network_height" ] || [ "$network_height" -eq 0 ] 2>/dev/null; then
                # 从日志中提取其他节点请求的最高区块号
                local request_heights=$(tail -1000 "$log_file" | grep -oE "\(height=[0-9]+\)" | grep -oE "[0-9]+" | sort -n | tail -1)
                if [ -n "$request_heights" ] && [ "$request_heights" -gt 0 ] 2>/dev/null; then
                    network_height=$request_heights
                fi
            fi

            # 显示全网高度和同步状态
            if [ -n "$network_height" ] && [ "$network_height" -gt 0 ] 2>/dev/null; then
                # 如果全网高度小于本地，使用本地高度
                if [ "$network_height" -lt "$block_num" ]; then
                    network_height=$block_num
                fi

                echo -e "全网高度: ${GREEN}#$network_height${NC}"
                local sync_diff=$((network_height - block_num))
                if [ "$sync_diff" -le 10 ]; then
                    echo -e "同步差距: ${GREEN}$sync_diff 个区块${NC} (已同步)"
                elif [ "$sync_diff" -le 100 ]; then
                    echo -e "同步差距: ${YELLOW}$sync_diff 个区块${NC} (接近同步)"
                else
                    echo -e "同步差距: ${YELLOW}$sync_diff 个区块${NC} (同步中)"
                fi
            else
                echo -e "全网高度: ${YELLOW}检测中...${NC}"
                echo "提示: 等待区块监控程序收集数据（约1分钟）"
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

    if [ -n "$network_height" ] && [ "$network_height" -gt 0 ] 2>/dev/null; then
        echo "全网高度: #$network_height"

        if [ -n "$local_height" ] && [ "$local_height" -gt 0 ] 2>/dev/null; then
            sync_diff=$((network_height - local_height))
            sync_percent=$((local_height * 100 / network_height))
            if [ "$sync_diff" -le 10 ]; then
                echo -e "同步进度: ${GREEN}${sync_percent}%${NC} (已同步，差距 $sync_diff 区块)"
            else
                echo -e "同步进度: ${YELLOW}${sync_percent}%${NC} (同步中，差距 $sync_diff 区块)"
            fi
        fi
    else
        echo "全网高度: 检测中..."
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

    echo -e "${GREEN}[日志分析]${NC}"
    local log_file=""
    if [ -f "$INSTALL_DIR/miner.log" ]; then
        log_file="$INSTALL_DIR/miner.log"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        log_file="$INSTALL_DIR/miner1.log"
    fi

    if [ -n "$log_file" ]; then
        echo "日志文件: $log_file"

        # 检查日志中是否有区块高度信息
        local tip_count=$(tail -500 "$log_file" | grep -c "tip=")
        local height_count=$(tail -500 "$log_file" | grep -c "height=")
        local sync_count=$(tail -500 "$log_file" | grep -c "\[sync\]")

        echo "最近500行日志统计:"
        echo "  - 包含 'tip=' 的行: $tip_count"
        echo "  - 包含 'height=' 的行: $height_count"
        echo "  - 包含 '[sync]' 的行: $sync_count"

        # 提取一些示例行
        echo ""
        echo "最近的 tip 记录:"
        tail -500 "$log_file" | grep "tip=" | tail -3 | sed 's/^/  /'

        echo ""
        echo "最近的 height 记录:"
        tail -500 "$log_file" | grep "height=" | tail -3 | sed 's/^/  /'
    else
        echo -e "${RED}未找到日志文件${NC}"
    fi

    echo ""
    echo -e "${GREEN}[建议]${NC}"
    if ! pgrep -f "block-monitor.sh" > /dev/null; then
        echo -e "${YELLOW}监控进程未运行，请尝试重启挖矿以启动监控${NC}"
    elif [ ! -f "$INSTALL_DIR/mining-stats.txt" ]; then
        echo -e "${YELLOW}统计文件不存在，监控程序可能刚启动，请等待1-2分钟${NC}"
    else
        local network_height=$(grep -oE '"network_height": [0-9]+' "$INSTALL_DIR/mining-stats.txt" | grep -oE '[0-9]+')
        if [ -z "$network_height" ] || [ "$network_height" -eq 0 ] 2>/dev/null; then
            echo -e "${YELLOW}全网高度为0或未获取，可能原因：${NC}"
            echo "  1. 节点正在同步中，还未收到其他节点的区块信息"
            echo "  2. 监控程序刚启动，等待1-2分钟后再查看"
            echo "  3. 日志中缺少区块高度信息"
        else
            echo -e "${GREEN}监控运行正常，全网高度: $network_height${NC}"
        fi
    fi

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
