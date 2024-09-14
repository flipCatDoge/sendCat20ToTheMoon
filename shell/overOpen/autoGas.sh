#!/bin/bash

# 检查 curl 是否存在
if ! command -v curl &> /dev/null; then
    echo "警告: 未找到 curl,请安装 curl 后再运行此脚本。"
    exit 1  # 终止脚本
fi
# 检查 jq 是否安装
if ! command -v jq &>/dev/null; then
    echo -e "${RED}jq not found. Please install jq to proceed.${NC}" >&2
    exit 1
fi

read -p "按'y'启动脚本: " user_input
if [[ $user_input == "y" ]]; then
    # 定义一个函数来更新 feeRate
    update_fee_rate() {
    while true; do
        # 获取当前时间
        currentTime=$(date +"%Y-%m-%d %H:%M:%S")
        
        # 获取 feeRate
        fastestFee=$(curl -s 'https://mempool.fractalbitcoin.io/api/v1/fees/recommended' | jq -r '.fastestFee')

        # 检查 curl 和 jq 是否成功
        if [ $? -ne 0 ]; then
            echo "[$currentTime] Error fetching fee rate."
            fastestFee=0
            # 将 feeRate 写入文件，用于其他脚本读取
            echo "$fastestFee" > /tmp/current_fee_rate.txt
            sleep 10
            continue
        fi
        
        # 打印当前时间和更新的 feeRate
        echo "[$currentTime] Updated fee rate to: $fastestFee"
        
        # 将 feeRate 写入文件，用于其他脚本读取
        echo "$fastestFee" > /tmp/current_fee_rate.txt

        # 每 3 秒更新一次
        sleep 3
    done
    }
    # 调用函数并将其放到后台
    update_fee_rate
else
    echo "停止执行。"
    exit 1
fi


