#!/bin/bash

# 离线模式 - 从日志推断全网高度的脚本
# 适用于无法访问外网 API 的环境

INSTALL_DIR="$HOME/csd-solo-miner"

# 查找日志文件
if [ -f "$INSTALL_DIR/miner.log" ]; then
    LOG_FILE="$INSTALL_DIR/miner.log"
elif [ -f "$INSTALL_DIR/miner1.log" ]; then
    LOG_FILE="$INSTALL_DIR/miner1.log"
else
    echo "错误: 未找到日志文件"
    exit 1
fi

echo "========================================"
echo "  离线模式 - 从日志推断区块高度"
echo "========================================"
echo ""

# 获取本地高度
echo "[1] 本地高度（从 RPC）"
echo "------------------------------------"
LOCAL_HEIGHT=""
for method in "eth_blockNumber" "cs_blockNumber"; do
    RPC_RESULT=$(curl -s -m 1 -X POST http://localhost:8789 \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}" 2>/dev/null)

    if [ -n "$RPC_RESULT" ] && echo "$RPC_RESULT" | grep -q "result"; then
        HEX=$(echo "$RPC_RESULT" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
        if [ -n "$HEX" ]; then
            LOCAL_HEIGHT=$((HEX))
            echo "本地高度: $LOCAL_HEIGHT"
            break
        fi
    fi
done

if [ -z "$LOCAL_HEIGHT" ]; then
    # 从日志提取本地高度
    TIP_LINE=$(tail -500 "$LOG_FILE" | grep -E "\[tip\].*h=[0-9]+" | tail -1)
    if [ -n "$TIP_LINE" ]; then
        LOCAL_HEIGHT=$(echo "$TIP_LINE" | grep -oE "h=[0-9]+" | grep -oE "[0-9]+" | tail -1)
        echo "本地高度（日志）: $LOCAL_HEIGHT"
    fi
fi
echo ""

# 从日志推断全网高度
echo "[2] 全网高度（从日志推断）"
echo "------------------------------------"

# 方法1: 从其他节点请求的区块高度中提取最大值
REQUEST_HEIGHTS=$(tail -2000 "$LOG_FILE" | grep -v "\[tip\]" | grep -oE "\(height=[0-9]+\)" | grep -oE "[0-9]+" | sort -n | tail -10)
if [ -n "$REQUEST_HEIGHTS" ]; then
    echo "最近请求的区块高度（最后10个）:"
    echo "$REQUEST_HEIGHTS" | tail -10 | sed 's/^/  /'
    MAX_REQUEST=$(echo "$REQUEST_HEIGHTS" | tail -1)
    echo ""
    echo "最高请求高度: $MAX_REQUEST"
fi

# 方法2: 检查是否有同步完成的标志
SYNC_COMPLETE=$(tail -500 "$LOG_FILE" | grep -c "已同步\|sync.*complete\|fully synced")
if [ "$SYNC_COMPLETE" -gt 0 ]; then
    echo "检测到同步完成标志"
    NETWORK_HEIGHT=$LOCAL_HEIGHT
else
    # 使用请求的最高高度
    if [ -n "$MAX_REQUEST" ]; then
        NETWORK_HEIGHT=$MAX_REQUEST
    fi
fi

echo ""
echo "========================================"
echo "  估算结果"
echo "========================================"
echo "本地高度: ${LOCAL_HEIGHT:-未知}"
echo "全网高度（估算）: ${NETWORK_HEIGHT:-未知}"

if [ -n "$LOCAL_HEIGHT" ] && [ -n "$NETWORK_HEIGHT" ]; then
    DIFF=$((NETWORK_HEIGHT - LOCAL_HEIGHT))
    if [ "$DIFF" -le 10 ]; then
        echo "同步状态: 已同步"
    elif [ "$DIFF" -le 100 ]; then
        echo "同步差距: $DIFF 区块（接近同步）"
    else
        PERCENT=$((LOCAL_HEIGHT * 100 / NETWORK_HEIGHT))
        echo "同步进度: ${PERCENT}%（差距 $DIFF 区块）"
    fi
fi

echo ""
echo "注意: 离线模式下的全网高度是根据日志推断的，"
echo "      可能不够准确。建议在能访问外网时使用 API。"
echo "========================================"
