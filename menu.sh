#!/bin/bash

# CSD Solo 挖矿管理菜单
# 一键下载运行: curl -fsSL https://raw.githubusercontent.com/gongxianga/csd-solo-mining/main/menu.sh -o menu.sh && chmod +x menu.sh && ./menu.sh

# 版本号
MENU_VERSION="v1.2.0"

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
    echo "8. 重启挖矿"
    echo "9. 卸载程序"
    echo "u. 更新菜单脚本"
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
            8) restart_mining ;;
            9) uninstall_program ;;
            u|U) update_menu ;;
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
