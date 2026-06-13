#!/bin/bash

# CSD Solo 挖矿管理菜单（整合优化版）
# 一键下载运行: curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o menu.sh && chmod +x menu.sh && ./menu.sh

# 版本号
MENU_VERSION="v3.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 安装目录
WORK_DIR="$HOME/csd-solo-mining"
LOG_FILE="$WORK_DIR/miner.log"
PID_FILE="$WORK_DIR/miner.pid"
DB_PATH="$HOME/.local/share/csd-solo-miner"

# 检查是否已安装
check_installation() {
    if [ -f "$WORK_DIR/csd-solo-miner" ]; then
        return 0
    else
        return 1
    fi
}

# 检查进程状态
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}运行中 (PID: $PID)${NC}"
            return 0
        fi
    fi

    if pgrep -f "csd-solo-miner" > /dev/null; then
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
    else
        echo -e "安装状态: ${YELLOW}未安装${NC}"
    fi

    echo -n "运行状态: "
    check_status

    # 显示资源状态
    local ulimit_n=$(ulimit -n)
    local has_swap=$(swapon -s 2>/dev/null | wc -l)

    echo ""
    echo -e "${YELLOW}[系统状态]${NC}"
    if [ "$ulimit_n" -ge 65536 ]; then
        echo -e "  文件描述符: ${GREEN}$ulimit_n${NC}"
    else
        echo -e "  文件描述符: ${RED}$ulimit_n (建议≥65536)${NC}"
    fi

    if [ "$has_swap" -gt 1 ]; then
        echo -e "  Swap 空间: ${GREEN}已启用${NC}"
    else
        echo -e "  Swap 空间: ${RED}未启用${NC}"
    fi

    echo ""
    echo -e "${BLUE}[程序管理]${NC}"
    echo "1. 安装/更新程序"
    echo "2. 启动挖矿"
    echo "3. 停止挖矿"
    echo "4. 重启挖矿"
    echo "5. 修复并启动（解决卡住问题）"
    echo ""
    echo -e "${BLUE}[监控查看]${NC}"
    echo "6. 查看实时日志 (Ctrl+C 退出)"
    echo "7. 查看最近日志"
    echo "8. 查看运行状态"
    echo ""
    echo -e "${BLUE}[系统工具]${NC}"
    echo "o. 系统优化（修复文件描述符/Swap/网络）"
    echo "d. 系统诊断"
    echo "u. 更新菜单脚本"
    echo "x. 卸载程序"
    echo "0. 退出"
    echo ""
    echo -n "请选择: "
}

# 安装程序
install_program() {
    echo ""
    echo -e "${BLUE}========== 安装 CSD Solo 挖矿程序 ==========${NC}"
    echo ""

    # 检查资源限制
    local current_limit=$(ulimit -n)
    if [ "$current_limit" -lt 65536 ]; then
        echo -e "${YELLOW}警告: 文件描述符限制较低 ($current_limit)${NC}"
        echo -e "${YELLOW}建议先运行系统优化（选项 o）${NC}"
        echo ""
        read -p "是否继续安装？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            return
        fi
    fi

    # 停止运行中的进程
    if pgrep -f "csd-solo-miner" > /dev/null; then
        echo "停止运行中的进程..."
        pkill -f "csd-solo-miner"
        sleep 2
    fi

    # 创建工作目录
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    # 获取最新版本
    echo -e "${BLUE}正在获取最新版本...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/dangraagu/CSD-Mining-pool-public/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}错误: 无法获取版本信息${NC}"
        read -p "按任意键返回..."
        return
    fi

    echo -e "${GREEN}最新版本: $LATEST_VERSION${NC}"

    # 下载程序
    BINARY_NAME="csd-solo-miner"
    DOWNLOAD_URL="https://github.com/dangraagu/CSD-Mining-pool-public/releases/download/${LATEST_VERSION}/csd-solo-miner-x86_64-unknown-linux-gnu"

    echo -e "${BLUE}正在下载程序...${NC}"
    curl -L -o "$BINARY_NAME" "$DOWNLOAD_URL" || {
        echo -e "${YELLOW}尝试 CPU 通用版本...${NC}"
        DOWNLOAD_URL="${DOWNLOAD_URL/x86_64-unknown-linux-gnu/cpu-x86_64-unknown-linux-gnu}"
        curl -L -o "$BINARY_NAME" "$DOWNLOAD_URL"
    }

    chmod +x "$BINARY_NAME"

    if [ -f "$BINARY_NAME" ] && [ -x "$BINARY_NAME" ]; then
        echo -e "${GREEN}安装完成！${NC}"
    else
        echo -e "${RED}安装失败！${NC}"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 启动挖矿
start_mining() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装，请先选择 1 安装程序${NC}"
        sleep 2
        return
    fi

    # 检查资源限制
    local current_limit=$(ulimit -n)
    if [ "$current_limit" -lt 65536 ]; then
        echo -e "${RED}错误: 文件描述符限制太低 ($current_limit)${NC}"
        echo -e "${YELLOW}请先运行系统优化（选项 o）${NC}"
        sleep 3
        return
    fi

    # 停止旧进程
    if pgrep -f "csd-solo-miner" > /dev/null; then
        echo -e "${YELLOW}检测到进程正在运行，是否停止并重启? (y/n)${NC}"
        read -n 1 confirm
        echo ""
        if [ "$confirm" = "y" ]; then
            pkill -f "csd-solo-miner"
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动挖矿...${NC}"

    cd "$WORK_DIR"

    # 设置环境变量
    export RUST_LOG=info
    export RUST_BACKTRACE=1

    # 清理旧日志
    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(wc -l < "$LOG_FILE")
        if [ "$LOG_SIZE" -gt 50000 ]; then
            echo -e "${YELLOW}日志文件过大，正在清理...${NC}"
            tail -10000 "$LOG_FILE" > "$LOG_FILE.tmp"
            mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi

    # 后台启动
    nohup ./csd-solo-miner > "$LOG_FILE" 2>&1 &
    MINER_PID=$!
    echo "$MINER_PID" > "$PID_FILE"

    sleep 3

    if ps -p "$MINER_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 启动成功！PID: $MINER_PID${NC}"
        echo ""
        echo "实时日志: tail -f $LOG_FILE"
    else
        echo -e "${RED}✗ 启动失败${NC}"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 停止挖矿
stop_mining() {
    echo ""

    if ! pgrep -f "csd-solo-miner" > /dev/null; then
        echo -e "${YELLOW}没有运行中的进程${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认停止挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在停止...${NC}"
        pkill -f "csd-solo-miner"
        sleep 2
        echo -e "${GREEN}已停止！${NC}"
    fi

    read -p "按任意键返回..."
}

# 修复并启动
fix_and_start() {
    echo ""
    echo -e "${BLUE}========== 修复并启动 ==========${NC}"
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    # 检查资源限制
    local current_limit=$(ulimit -n)
    echo -e "${YELLOW}当前文件描述符限制: $current_limit${NC}"

    if [ "$current_limit" -lt 65536 ]; then
        echo -e "${RED}警告: 文件描述符限制太低！${NC}"
        echo -e "${YELLOW}正在尝试提高限制...${NC}"
        ulimit -n 65536 2>/dev/null || {
            echo -e "${RED}无法提高限制，请先运行系统优化（选项 o）${NC}"
            sleep 3
            return
        }
        echo -e "${GREEN}✓ 限制已提高到: $(ulimit -n)${NC}"
    fi

    # 停止旧进程
    if pgrep -f "csd-solo-miner" > /dev/null; then
        echo "正在停止旧进程..."
        pkill -f "csd-solo-miner"
        sleep 2
    fi

    # 询问是否清理数据库
    echo ""
    echo -e "${YELLOW}检测到同步问题，你有以下选项：${NC}"
    echo -e "  ${GREEN}1)${NC} 继续从当前位置同步（保留数据）"
    echo -e "  ${GREEN}2)${NC} 清理数据库重新同步（推荐，如果一直卡住）"
    echo -e "  ${GREEN}3)${NC} 只清理损坏的数据（保守方案）"
    echo ""
    read -p "请选择 [1/2/3]: " choice

    case $choice in
        2)
            echo -e "${YELLOW}正在清理数据库...${NC}"
            if [ -d "$DB_PATH" ]; then
                DB_SIZE=$(du -sh "$DB_PATH" 2>/dev/null | cut -f1)
                echo -e "${BLUE}数据库大小: $DB_SIZE${NC}"

                read -p "是否备份当前数据库？(y/n): " backup_choice
                if [ "$backup_choice" = "y" ]; then
                    BACKUP_NAME="csd-backup-$(date +%Y%m%d-%H%M%S)"
                    echo -e "${YELLOW}正在备份到 ~/$BACKUP_NAME...${NC}"
                    mv "$DB_PATH" "$HOME/$BACKUP_NAME"
                else
                    rm -rf "$DB_PATH"
                fi
                echo -e "${GREEN}✓ 数据库已清理${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}正在清理损坏的数据...${NC}"
            rm -rf "$DB_PATH"/chains/*/db/parachains 2>/dev/null
            rm -rf "$DB_PATH"/chains/*/db/full-*.log 2>/dev/null
            echo -e "${GREEN}✓ 已清理${NC}"
            ;;
        *)
            echo -e "${GREEN}保持现有数据${NC}"
            ;;
    esac

    # 启动程序
    echo ""
    echo -e "${GREEN}正在启动程序...${NC}"

    cd "$WORK_DIR"
    export RUST_LOG=info
    export RUST_BACKTRACE=1

    nohup ./csd-solo-miner > "$LOG_FILE" 2>&1 &
    MINER_PID=$!
    echo "$MINER_PID" > "$PID_FILE"

    sleep 3

    if ps -p "$MINER_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 启动成功！PID: $MINER_PID${NC}"
        echo ""
        tail -30 "$LOG_FILE"
    else
        echo -e "${RED}✗ 启动失败${NC}"
        cat "$LOG_FILE"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 查看实时日志
view_logs() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}未找到日志文件${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}提示：按 Ctrl+C 可以退出日志查看${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    echo ""
    sleep 1

    (
        trap 'echo -e "\n${GREEN}退出日志查看...${NC}"; exit 0' INT
        tail -f "$LOG_FILE"
    )

    echo ""
    read -p "按任意键返回..."
}

# 查看最近日志
view_recent_logs() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}未找到日志文件${NC}"
        sleep 2
        return
    fi

    echo -e "${GREEN}========== 最近50行日志 ==========${NC}"
    echo ""
    tail -n 50 "$LOG_FILE"

    echo ""
    read -p "按任意键返回..."
}

# 查看运行状态
view_status() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "         运行状态监控"
    echo -e "==========================================${NC}"

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        read -p "按任意键返回..."
        return
    fi

    echo -e "${GREEN}[进程信息]${NC}"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "状态: ${GREEN}运行中 (PID: $PID)${NC}"

            ps -p "$PID" -o pid,vsz,rss,%cpu,%mem,etime,cmd --no-headers | \
            awk '{
                printf "  虚拟内存: %.1f MB\n", $2/1024
                printf "  物理内存: %.1f MB\n", $3/1024
                printf "  CPU 使用: %s%%\n", $4
                printf "  内存使用: %s%%\n", $5
                printf "  运行时间: %s\n", $6
            }'

            FD_COUNT=$(ls -1 /proc/$PID/fd 2>/dev/null | wc -l)
            FD_LIMIT=$(cat /proc/$PID/limits 2>/dev/null | grep "open files" | awk '{print $4}')
            echo -e "  文件描述符: $FD_COUNT / $FD_LIMIT"
        else
            echo -e "状态: ${RED}未运行 (PID 文件存在但进程不存在)${NC}"
        fi
    else
        echo -e "状态: ${RED}未运行${NC}"
    fi
    echo ""

    # 同步状态
    echo -e "${GREEN}[同步状态]${NC}"
    if [ -f "$LOG_FILE" ]; then
        LAST_HEIGHT=$(tail -100 "$LOG_FILE" | grep -oP 'local_height=\K[0-9]+' | tail -1)
        BEST_HEIGHT=$(tail -100 "$LOG_FILE" | grep -oP 'best_peer_height=\K[0-9]+' | tail -1)
        PEERS=$(tail -100 "$LOG_FILE" | grep -oP 'peers=\K[0-9]+' | tail -1)

        if [ -n "$LAST_HEIGHT" ]; then
            echo -e "  本地高度: ${GREEN}$LAST_HEIGHT${NC}"
            echo -e "  最佳高度: ${GREEN}$BEST_HEIGHT${NC}"
            echo -e "  连接节点: ${GREEN}$PEERS${NC}"

            if [ -n "$BEST_HEIGHT" ]; then
                SYNC_GAP=$((BEST_HEIGHT - LAST_HEIGHT))
                if [ "$SYNC_GAP" -le 10 ]; then
                    echo -e "  同步差距: ${GREEN}$SYNC_GAP 个区块 (已同步)${NC}"
                else
                    echo -e "  同步差距: ${YELLOW}$SYNC_GAP 个区块 (同步中)${NC}"
                fi
            fi
        else
            echo -e "  ${YELLOW}同步中...${NC}"
        fi

        # 检查日志更新时间
        LAST_UPDATE=$(stat -c %Y "$LOG_FILE" 2>/dev/null)
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))

        if [ "$TIME_DIFF" -gt 300 ]; then
            echo -e "  ${RED}警告: 日志超过 $((TIME_DIFF/60)) 分钟未更新！${NC}"
        else
            echo -e "  ${GREEN}日志活跃: $TIME_DIFF 秒前更新${NC}"
        fi
    fi
    echo ""

    # 最近日志
    echo -e "${GREEN}[最近日志]${NC} (最后10行)"
    if [ -f "$LOG_FILE" ]; then
        tail -10 "$LOG_FILE" | sed 's/^/  /'
    fi

    echo ""
    read -p "按任意键返回..."
}

# 系统优化
system_optimize() {
    echo ""
    echo -e "${BLUE}========== 系统优化 ==========${NC}"
    echo ""

    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误: 需要 root 权限运行此功能${NC}"
        echo -e "${YELLOW}请使用: sudo bash $0${NC}"
        echo -e "${YELLOW}或者在菜单中选择后输入管理员密码${NC}"
        echo ""
        read -p "是否尝试使用 sudo 运行优化？(y/n): " confirm
        if [ "$confirm" = "y" ]; then
            sudo bash -c "$(declare -f system_optimize_root); system_optimize_root"
            read -p "按任意键返回..."
        fi
        return
    fi

    system_optimize_root
    read -p "按任意键返回..."
}

# 系统优化（root部分）
system_optimize_root() {
    echo -e "${YELLOW}[1/6] 设置文件描述符限制...${NC}"

    # 备份配置文件
    if [ ! -f /etc/security/limits.conf.bak ]; then
        cp /etc/security/limits.conf /etc/security/limits.conf.bak
    fi

    # 检查是否已存在配置
    if ! grep -q "CSD Mining" /etc/security/limits.conf; then
        cat >> /etc/security/limits.conf << 'EOF'
# CSD Mining 优化
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF
        echo -e "${GREEN}✓ 文件描述符限制已设置${NC}"
    else
        echo -e "${GREEN}✓ 文件描述符限制已存在${NC}"
    fi

    echo -e "${YELLOW}[2/6] 设置系统级文件限制...${NC}"
    if ! grep -q "fs.file-max = 2097152" /etc/sysctl.conf; then
        echo "fs.file-max = 2097152" >> /etc/sysctl.conf
        echo -e "${GREEN}✓ 系统文件限制已设置${NC}"
    else
        echo -e "${GREEN}✓ 系统文件限制已存在${NC}"
    fi

    echo -e "${YELLOW}[3/6] 检查 Swap 空间...${NC}"
    if [ $(swapon -s | wc -l) -le 1 ]; then
        echo -e "${BLUE}正在创建 4GB Swap 文件...${NC}"

        if [ ! -f /swapfile ]; then
            dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile

            if ! grep -q "/swapfile" /etc/fstab; then
                echo "/swapfile none swap sw 0 0" >> /etc/fstab
            fi

            if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
                echo "vm.swappiness = 10" >> /etc/sysctl.conf
            fi

            echo -e "${GREEN}✓ Swap 空间创建完成${NC}"
        else
            swapon /swapfile 2>/dev/null
            echo -e "${GREEN}✓ Swap 文件已存在并启用${NC}"
        fi
    else
        echo -e "${GREEN}✓ Swap 已存在${NC}"
    fi

    echo -e "${YELLOW}[4/6] 优化网络内核参数...${NC}"
    if ! grep -q "CSD Mining 网络优化" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf << 'EOF'

# CSD Mining 网络优化
net.ipv4.ip_local_port_range = 10000 65535
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
EOF
        echo -e "${GREEN}✓ 网络参数已设置${NC}"
    else
        echo -e "${GREEN}✓ 网络参数已存在${NC}"
    fi

    echo -e "${YELLOW}[5/6] 应用内核参数...${NC}"
    sysctl -p > /dev/null 2>&1
    echo -e "${GREEN}✓ 参数已应用${NC}"

    echo -e "${YELLOW}[6/6] 创建环境配置...${NC}"
    if [ ! -f /etc/profile.d/csd-mining.sh ]; then
        cat > /etc/profile.d/csd-mining.sh << 'EOF'
# CSD Mining 环境变量
export RUST_LOG=info
export RUST_BACKTRACE=1
ulimit -n 65536
EOF
        echo -e "${GREEN}✓ 环境配置已创建${NC}"
    else
        echo -e "${GREEN}✓ 环境配置已存在${NC}"
    fi

    echo ""
    echo -e "${BLUE}====================================${NC}"
    echo -e "${GREEN}系统优化完成！${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo ""
    echo -e "${YELLOW}优化项目总结：${NC}"
    echo -e "  ✓ 文件描述符限制: 65536"
    echo -e "  ✓ Swap 空间: 4GB"
    echo -e "  ✓ 端口范围: 10000-65535"
    echo -e "  ✓ TCP 连接队列: 8192"
    echo -e "  ✓ 网络缓冲区已优化"
    echo ""
    echo -e "${RED}重要: 需要重新登录或重启系统使所有设置生效！${NC}"
    echo ""
    echo -e "${YELLOW}建议操作：${NC}"
    echo -e "  1. 退出并重新登录 SSH"
    echo -e "  2. 或执行: exec sudo su - $SUDO_USER"
    echo -e "  3. 验证设置: ulimit -n"
    echo ""
}

# 系统诊断
system_diagnostic() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "         系统诊断"
    echo -e "==========================================${NC}"
    echo ""

    echo -e "${YELLOW}[1] 系统资源${NC}"
    echo -e "文件描述符限制: $(ulimit -n)"
    echo -e "进程数限制: $(ulimit -u)"
    echo -e "系统最大文件: $(cat /proc/sys/fs/file-max)"
    echo ""

    echo -e "${YELLOW}[2] 内存状态${NC}"
    free -h
    echo ""

    echo -e "${YELLOW}[3] Swap 状态${NC}"
    if [ $(swapon -s | wc -l) -gt 1 ]; then
        swapon -s
        echo -e "${GREEN}✓ Swap 已启用${NC}"
    else
        echo -e "${RED}✗ 没有 Swap 空间！${NC}"
    fi
    echo ""

    echo -e "${YELLOW}[4] 网络参数${NC}"
    echo "端口范围: $(cat /proc/sys/net/ipv4/ip_local_port_range)"
    echo "TCP SYN backlog: $(cat /proc/sys/net/ipv4/tcp_max_syn_backlog)"
    echo "连接队列: $(cat /proc/sys/net/core/somaxconn)"
    echo ""

    echo -e "${YELLOW}[5] 进程状态${NC}"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 进程正在运行 (PID: $PID)${NC}"

            FD_COUNT=$(ls -1 /proc/$PID/fd 2>/dev/null | wc -l)
            FD_LIMIT=$(cat /proc/$PID/limits 2>/dev/null | grep "open files" | awk '{print $4}')
            echo "  文件描述符: $FD_COUNT / $FD_LIMIT"

            if [ "$FD_COUNT" -gt $((FD_LIMIT * 80 / 100)) ]; then
                echo -e "  ${RED}警告: 文件描述符使用率超过 80%！${NC}"
            fi
        else
            echo -e "${RED}✗ 进程未运行${NC}"
        fi
    else
        echo -e "${YELLOW}✗ 没有找到 PID 文件${NC}"
    fi
    echo ""

    echo -e "${YELLOW}[6] 诊断建议${NC}"
    local need_optimize=0

    if [ $(ulimit -n) -lt 65536 ]; then
        echo -e "  ${RED}✗${NC} 文件描述符限制太低"
        need_optimize=1
    fi

    if [ $(swapon -s | wc -l) -le 1 ]; then
        echo -e "  ${RED}✗${NC} 没有 Swap 空间"
        need_optimize=1
    fi

    if [ "$need_optimize" -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}建议运行系统优化（选项 o）${NC}"
    else
        echo -e "  ${GREEN}✓ 系统配置良好${NC}"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 重启挖矿
restart_mining() {
    echo ""

    if ! check_installation; then
        echo -e "${RED}错误: 尚未安装${NC}"
        sleep 2
        return
    fi

    if ! pgrep -f "csd-solo-miner" > /dev/null; then
        echo -e "${YELLOW}没有运行中的进程，请使用启动功能${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}确认重启挖矿? (y/n)${NC}"
    read -n 1 confirm
    echo ""

    if [ "$confirm" = "y" ]; then
        echo -e "${GREEN}正在重启...${NC}"
        pkill -f "csd-solo-miner"
        sleep 3
        start_mining
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
        if pgrep -f "csd-solo-miner" > /dev/null; then
            echo "停止运行中的进程..."
            pkill -f "csd-solo-miner"
            sleep 2
        fi

        echo "删除安装目录..."
        rm -rf "$WORK_DIR"
        rm -rf "$DB_PATH"

        echo ""
        echo -e "${GREEN}卸载完成！${NC}"
    else
        echo "已取消"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 更新菜单脚本
update_menu() {
    echo ""
    echo -e "${BLUE}========== 更新菜单脚本 ==========${NC}"
    echo ""

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
    else
        echo -e "${RED}错误: 未找到 curl${NC}"
    fi

    echo ""
    read -p "按任意键返回..."
}

# 主循环
main() {
    while true; do
        show_menu
        read choice

        case $choice in
            1) install_program ;;
            2) start_mining ;;
            3) stop_mining ;;
            4) restart_mining ;;
            5) fix_and_start ;;
            6) view_logs ;;
            7) view_recent_logs ;;
            8) view_status ;;
            o|O) system_optimize ;;
            d|D) system_diagnostic ;;
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
