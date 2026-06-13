#!/bin/bash

echo "========================================"
echo "  快速修复和测试脚本"
echo "========================================"
echo ""

# 测试网络连接
echo "[1] 测试网络连接"
echo "------------------------------------"
echo -n "测试 API 连接: "
if curl -s -m 3 "https://cairn-substrate.com/explorer/api/blocks/tip/height" > /dev/null 2>&1; then
    echo "✓ 成功"
    API_WORKING=1
else
    echo "✗ 失败"
    API_WORKING=0
fi
echo ""

# 获取全网高度
if [ "$API_WORKING" -eq 1 ]; then
    echo "[2] 获取全网高度"
    echo "------------------------------------"
    NETWORK_HEIGHT=$(curl -s -m 3 "https://cairn-substrate.com/explorer/api/blocks/tip/height" 2>/dev/null | grep -oE '^[0-9]+$')
    if [ -n "$NETWORK_HEIGHT" ] && [ "$NETWORK_HEIGHT" -gt 0 ] 2>/dev/null; then
        echo "全网高度: $NETWORK_HEIGHT"
    else
        echo "获取失败"
    fi
    echo ""
fi

# 获取本地高度
echo "[3] 获取本地高度"
echo "------------------------------------"
LOCAL_HEIGHT=""
for method in "eth_blockNumber" "cs_blockNumber" "substrate_blockNumber"; do
    echo -n "测试 $method: "
    RPC_RESULT=$(curl -s -m 2 -X POST http://localhost:8789 \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}" 2>/dev/null)

    if [ -n "$RPC_RESULT" ] && echo "$RPC_RESULT" | grep -q "result"; then
        HEX=$(echo "$RPC_RESULT" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
        if [ -n "$HEX" ]; then
            LOCAL_HEIGHT=$((HEX))
            echo "✓ 成功 (高度: $LOCAL_HEIGHT)"
            break
        else
            echo "✗ 无高度数据"
        fi
    else
        echo "✗ 失败"
    fi
done
echo ""

# 从日志获取全网高度（备用方案）
if [ "$API_WORKING" -eq 0 ]; then
    echo "[4] 从日志推断全网高度（备用方案）"
    echo "------------------------------------"

    # 查找日志文件
    if [ -f "$HOME/csd-solo-miner/miner.log" ]; then
        LOG_FILE="$HOME/csd-solo-miner/miner.log"
    elif [ -f "$HOME/csd-solo-miner/miner1.log" ]; then
        LOG_FILE="$HOME/csd-solo-miner/miner1.log"
    fi

    if [ -n "$LOG_FILE" ]; then
        echo "分析日志: $LOG_FILE"

        # 方法1: 从 request block 中提取
        REQUEST_HEIGHT=$(tail -1000 "$LOG_FILE" | grep -v "\[tip\]" | grep -oE "\(height=[0-9]+\)" | grep -oE "[0-9]+" | sort -n | tail -1)
        if [ -n "$REQUEST_HEIGHT" ] && [ "$REQUEST_HEIGHT" -gt 0 ] 2>/dev/null; then
            echo "  - 从请求日志推断: $REQUEST_HEIGHT"
            NETWORK_HEIGHT=$REQUEST_HEIGHT
        fi

        # 方法2: 从 got headers 中提取
        HEADER_HEIGHT=$(tail -1000 "$LOG_FILE" | grep "got headers" | grep -oE "count=[0-9]+" | grep -oE "[0-9]+" | sort -n | tail -1)
        if [ -n "$HEADER_HEIGHT" ] && [ "$HEADER_HEIGHT" -gt 0 ] 2>/dev/null; then
            echo "  - 收到 headers 数量: $HEADER_HEIGHT"
            if [ -n "$LOCAL_HEIGHT" ]; then
                ESTIMATED=$((LOCAL_HEIGHT + HEADER_HEIGHT))
                echo "  - 估算全网高度: $ESTIMATED"
                if [ -z "$NETWORK_HEIGHT" ] || [ "$ESTIMATED" -gt "$NETWORK_HEIGHT" ]; then
                    NETWORK_HEIGHT=$ESTIMATED
                fi
            fi
        fi

        if [ -n "$NETWORK_HEIGHT" ] && [ "$NETWORK_HEIGHT" -gt 0 ] 2>/dev/null; then
            echo ""
            echo "推断的全网高度: $NETWORK_HEIGHT"
        else
            echo ""
            echo "无法从日志推断全网高度"
        fi
    else
        echo "未找到日志文件"
    fi
    echo ""
fi

# 显示总结
echo "========================================"
echo "  总结"
echo "========================================"
if [ -n "$LOCAL_HEIGHT" ] && [ "$LOCAL_HEIGHT" -gt 0 ] 2>/dev/null; then
    echo "✓ 本地高度: $LOCAL_HEIGHT"
else
    echo "✗ 本地高度: 获取失败"
fi

if [ -n "$NETWORK_HEIGHT" ] && [ "$NETWORK_HEIGHT" -gt 0 ] 2>/dev/null; then
    echo "✓ 全网高度: $NETWORK_HEIGHT"

    if [ -n "$LOCAL_HEIGHT" ]; then
        DIFF=$((NETWORK_HEIGHT - LOCAL_HEIGHT))
        if [ "$DIFF" -lt 0 ]; then
            DIFF=$((LOCAL_HEIGHT - NETWORK_HEIGHT))
            echo "  同步状态: 本地超前 $DIFF 区块"
        elif [ "$DIFF" -le 10 ]; then
            echo "  同步状态: 已同步 (差距 $DIFF 区块)"
        else
            PERCENT=$((LOCAL_HEIGHT * 100 / NETWORK_HEIGHT))
            echo "  同步进度: ${PERCENT}% (差距 $DIFF 区块)"
        fi
    fi
else
    if [ "$API_WORKING" -eq 0 ]; then
        echo "✗ 全网高度: API 不可访问"
        echo ""
        echo "建议方案："
        echo "1. 检查网络连接和防火墙"
        echo "2. 使用日志推断的高度（不够准确）"
        echo "3. 如果节点已同步，本地高度即是全网高度"
    else
        echo "✗ 全网高度: 获取失败"
    fi
fi
echo ""

# 重启建议
if pgrep -f "block-monitor.sh" > /dev/null; then
    echo "提示: 检测到监控进程正在运行"
    echo "      如果刚更新了脚本，建议重启挖矿以应用新配置"
    echo "      在菜单中选择 '9. 重启挖矿'"
fi

echo "========================================"
