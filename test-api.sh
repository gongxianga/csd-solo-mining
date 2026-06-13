#!/bin/bash

# 测试脚本 - 验证全网高度和本地高度获取

echo "========================================"
echo "  CSD 高度获取测试"
echo "========================================"
echo ""

echo "[1] 测试本地 RPC 接口"
echo "------------------------------------"
for method in "eth_blockNumber" "cs_blockNumber" "substrate_blockNumber"; do
    echo "测试方法: $method"
    result=$(curl -s -m 2 -X POST http://localhost:8789 \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}")

    if [ -n "$result" ]; then
        echo "响应: $result"
        if echo "$result" | grep -q "result"; then
            hex=$(echo "$result" | grep -oE '"result":"0x[0-9a-fA-F]+"' | grep -oE '0x[0-9a-fA-F]+')
            if [ -n "$hex" ]; then
                dec=$((hex))
                echo "✓ 成功获取本地高度: $dec"
            fi
        fi
    else
        echo "✗ 无响应"
    fi
    echo ""
done

echo "[2] 测试全网高度 API"
echo "------------------------------------"
echo "API 端点: https://cairn-substrate.com/explorer/api/blocks/tip/height"
result=$(curl -s -m 3 "https://cairn-substrate.com/explorer/api/blocks/tip/height")
echo "响应: $result"
if [ -n "$result" ]; then
    height=$(echo "$result" | grep -oE '^[0-9]+$')
    if [ -n "$height" ] && [ "$height" -gt 0 ] 2>/dev/null; then
        echo "✓ 成功获取全网高度: $height"
    else
        echo "✗ 响应格式错误"
    fi
else
    echo "✗ 无响应或超时"
fi
echo ""

echo "API 端点: https://cairn-substrate.com/explorer/api/health"
result=$(curl -s -m 3 "https://cairn-substrate.com/explorer/api/health")
echo "响应: $(echo "$result" | head -c 200)..."
if [ -n "$result" ]; then
    height=$(echo "$result" | grep -oE '"indexed_height":[0-9]+' | grep -oE '[0-9]+')
    if [ -n "$height" ] && [ "$height" -gt 0 ] 2>/dev/null; then
        echo "✓ 成功获取索引高度: $height"
    else
        echo "✗ 响应中无高度数据"
    fi
else
    echo "✗ 无响应或超时"
fi
echo ""

echo "========================================"
echo "测试完成"
echo "========================================"
