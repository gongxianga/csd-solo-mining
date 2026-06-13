#!/bin/bash

# CSD Solo 挖矿管理菜单
# 一键下载运行: curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o menu.sh && chmod +x menu.sh && ./menu.sh

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
    echo "  CSD Solo 挖矿管理菜单"
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
    echo "5. 查看实时日志"
    echo "6. 查看运行状态"
    echo "7. 重启挖矿"
    echo "8. 卸载程序"
    echo "0. 退出"
    echo ""
    echo -n "请选择 [0-8]: "
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
            cd "$INSTALL_DIR" && bash stop-mining.sh
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动单显卡挖矿...${NC}"
    cd "$INSTALL_DIR" && bash start-mining.sh "$wallet"
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
            cd "$INSTALL_DIR" && bash stop-mining.sh
            sleep 2
        else
            return
        fi
    fi

    echo -e "${GREEN}正在启动 $gpu_count 显卡挖矿...${NC}"
    cd "$INSTALL_DIR" && bash start-multi-gpu.sh "$wallet" "$gpu_count"
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
        cd "$INSTALL_DIR" && bash stop-mining.sh
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

    if [ -f "$INSTALL_DIR/miner.log" ]; then
        echo -e "${GREEN}单显卡日志 (Ctrl+C 退出):${NC}"
        echo "文件: $INSTALL_DIR/miner.log"
        echo ""
        tail -f "$INSTALL_DIR/miner.log"
    elif [ -f "$INSTALL_DIR/miner1.log" ]; then
        echo -e "${GREEN}多显卡日志 - 显卡1 (Ctrl+C 退出):${NC}"
        echo "文件: $INSTALL_DIR/miner1.log"
        echo ""
        tail -f "$INSTALL_DIR/miner1.log"
    else
        echo -e "${RED}未找到日志文件${NC}"
        echo "目录: $INSTALL_DIR"
        sleep 2
    fi
}

# 查看状态
view_status() {
    echo ""
    echo -e "${BLUE}========== 运行状态 ==========${NC}"

    if ! check_installation; then
        echo -e "${YELLOW}程序未安装${NC}"
        echo ""
        echo "按任意键返回菜单..."
        read -n 1
        return
    fi

    echo "安装目录: $INSTALL_DIR"
    echo ""

    if pgrep -f "csd node" > /dev/null; then
        echo "进程列表:"
        ps aux | grep "csd node" | grep -v grep
        echo ""
        echo "日志文件:"
        ls -lh "$INSTALL_DIR"/*.log 2>/dev/null || echo "  无日志文件"
        echo ""
        echo "数据目录:"
        ls -lhd "$INSTALL_DIR"/cs*.db 2>/dev/null || echo "  无数据目录"
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
        cd "$INSTALL_DIR" && bash stop-mining.sh
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
            6) view_status ;;
            7) restart_mining ;;
            8) uninstall_program ;;
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
