#!/bin/bash

# 颜色定义
RED='\033[0;31m'
NC='\033[0m' # 无色

# 检查 curl 是否存在
if ! command -v curl &> /dev/null; then
    echo -e "${RED}警告: 未找到 curl, 请安装 curl 后再运行此脚本。${NC}" >&2
    exit 1
fi

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}警告: 未找到 jq, 请安装 jq 后再运行此脚本。${NC}" >&2
    exit 1
fi

read -p "按'y'启动脚本: " user_input
if [[ $user_input == "y" ]]; then
    # 定义一个函数来更新 feeRate
    update_fee_rate() {
        trap 'kill $!' EXIT  # 捕获退出信号
        while true; do
            # 获取当前时间
            currentTime=$(date +"%Y-%m-%d %H:%M:%S")
            
            # 获取 feeRate
            fastestFee=$(curl -s 'https://mempool.fractalbitcoin.io/api/v1/fees/recommended' | jq -r '.fastestFee') || {
                echo "[$currentTime] Error fetching fee rate."
                fastestFee=0
            }
            # 打印当前时间和更新的 feeRate
            echo "[$currentTime] Updated fee rate to: $fastestFee"
            
            # 将 feeRate 写入文件，用于其他脚本读取
            echo "$fastestFee" > /tmp/current_fee_rate.txt

            # 每 2 秒更新一次
            sleep 2
        done
    }
    # 调用函数并将其放到后台
    update_fee_rate
else
    echo "停止执行。"
    exit 1
fi


