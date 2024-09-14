#!/bin/bash

# 使用如报错请先执行命令 sudo apt-get install jq
# sudo apt-get install curl
# CentOS/RHEL的linux系统，将上方apt-get替换为yum指令
# 信息捕手聚合社区 - 脚本工具 + KOL信息 + 监控工具 全聚合～
# 购买联系客服微信：coecvyy

myconfig="demo.json" #想实现多打，可在/cli目录下创建不同的json文件，并将此处替换
log_file="mint_log.txt"
success_count=0

# 初始化日志文件
echo "Minting Script Started at $(date)" | tee -a $log_file
# ANSI 转义码定义
RED='\033[0;31m'    # 红色
GREEN='\033[0;32m'  # 绿色
YELLOW='\033[0;33m' # 黄色
NC='\033[0m'        # 无颜色

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

# 定义命令
createWallet="sudo yarn cli wallet create --config $myconfig"
showAddress="sudo yarn cli wallet address --config $myconfig"
showBalances="sudo yarn cli wallet balances --config $myconfig"
exportWallet="sudo yarn cli wallet export --create true --config $myconfig"
echo -e "${GREEN}1. 创建新钱包;${NC}"
echo -e "${GREEN}2. 显示钱包地址;${NC}"
echo -e "${GREEN}3. 显示钱包cat tokens;${NC}"
echo -e "${GREEN}4. 将钱包注册到本地节点;${NC}"
echo -e "${GREEN}5. 转账;${NC}"
echo -e "${GREEN}6. 自动开打${NC}"
# 读取用户输入
read -p "请输入选项 [1~6]: " user_input
if [[ $user_input == "1" ]]; then
    echo "-------------------------------------------"
    echo "--------------create wallet----------------"
    echo "-------------------------------------------"
    $createWallet
elif [[ $user_input == "2" ]]; then
    echo "-------------------------------------------"
    echo "-----------show wallet address-------------"
    echo "-------------------------------------------"
    $showAddress
elif [[ $user_input == "3" ]]; then
    echo "-------------------------------------------"
    echo "-----------show wallet address-------------"
    echo "-------------------------------------------"
    $showBalances
elif [[ $user_input == "4" ]];then
    echo "-------------------------------------------"
    echo "-----------show wallet address-------------"
    echo "-------------------------------------------"
    $exportWallet
elif [[ $user_input == "5" ]];then
    echo "-------------------------------------------"
    echo "---------------send tokens-----------------"
    echo "-------------------------------------------"
    read -p "请输入转账token合约,直接回车,默认为first cat token: " token
    if [[ -z "$token" ]]; then
        token='45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0'
    fi
    read -p "请输入接收方地址: " receiver
    read -p "请输入转账数量: " amount
    read -p "请输入 'y' 确认转账: " user_input
    if [[ $user_input == "y" ]]; then
        feeRate=$(curl -s 'https://mempool.fractalbitcoin.io/api/v1/fees/recommended' | jq -r '.fastestFee')
        echo "The mempool fee rate is: $feeRate"
        echo -e "正在使用当前 $feeRate 费率进行 ${GREEN}转账${NC}" | tee -a $log_file
        # 检查 feeRate 是否为有效的整数
        if [[ "$feeRate" == 0 ]]; then
            echo -e "${RED}获取链上当前gas失败: $feeRate,请稍后重试${NC}" | tee -a $log_file
            echo "正在退出本脚本...."
            exit 1
        fi
        sendMaxFee=500
        # 比较 feeRate 是否大于 500
        if [ "$feeRate" -gt $sendMaxFee ]; then
            echo -e "${YELLOW}费率超过 $sendMaxFee,跳过当前循环${NC}" | tee -a $log_file
            echo "更改脚本中'sendMaxFee'参数,可自定义能接受的最大gas费,默认按照链上当前gas转账"
            echo "取消转账，退出本脚本..."
            exit 1
        fi
        sendTokens="sudo yarn cli send -i $token $receiver $amount --fee-rate $feeRate --config $myconfig"
        $sendTokens
    else
        echo "取消转账，退出本脚本"
    fi
else
    read -p "请输入需要mint的token合约: " token
    read -p "请输入需要mint的数量: " amount
    read -p "自动开打，输入 'y' 确认: " user_input
    if [[ $user_input == "y" ]]; then
        echo "开始自动mint..."
        # 循环
        while true; do
            # 检查文件是否存在
            if [ -f /tmp/current_fee_rate.txt ]; then
                # 从文件中读取 feeRate
                feeRate=$(cat /tmp/current_fee_rate.txt)
                echo "The mempool fee rate is: $feeRate"
                # 检查 feeRate 是否为有效的整数
                if [[ "$feeRate" == 0 ]]; then
                    echo -e "${YELLOW}获取链上当前gas失败: $feeRate,4s后稍后重试${NC}" | tee -a $log_file
                    feeRate=0 # 或者设置为一个合适的默认值
                    sleep 4
                    continue
                fi
            else
                feeRate=$(curl -s 'https://mempool.fractalbitcoin.io/api/v1/fees/recommended' | jq -r '.fastestFee')
                echo "The mempool fee rate is: $feeRate"
                # 检查 feeRate 是否为有效的整数
                if [[ "$feeRate" == 0 ]]; then
                    echo -e "${RED}获取链上当前gas失败: $feeRate,10s后稍后重试${NC}" | tee -a $log_file
                    feeRate=0 # 或者设置为一个合适的默认值
                    sleep 10
                    continue
                fi
            fi
            echo -e "正在使用当前 $feeRate 费率进行 ${GREEN}Mint${NC}" | tee -a $log_file

            # 检查 feeRate 是否为有效的整数
            if ! [[ "$feeRate" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}获取的费率无效或为空: $feeRate ${NC}" | tee -a $log_file
                feeRate=0 # 或者设置为一个合适的默认值
                sleep 4
                continue
            fi
            mintMaxFee=2000
            # 比较 mintMaxFee 是否大于 2000
            if [ "$feeRate" -gt $mintMaxFee ]; then
                echo -e "${YELLOW}费率超过 $mintMaxFee,跳过当前循环${NC}" | tee -a $log_file
                sleep 4
                continue
            fi

            # command="yarn cli mint -i 45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0 5 --fee-rate $feeRate --config $myconfig"
            # command="yarn cli mint -i f31030e87fec4a7e47fab51c842b1168e1396a89ec9ab6743e7a72495199cc3c_0 1000 --fee-rate $feeRate --config $myconfig"
            command="yarn cli mint -i $token $amount --fee-rate $feeRate --config $myconfig"

            $command
            command_status=$?

            if [ $command_status -ne 0 ]; then
                echo "命令执行失败，退出循环" | tee -a $log_file
                exit 1
            else
                success_count=$((success_count + 1))
                echo "成功mint了 $success_count 次" | tee -a $log_file
            fi

            sleep 3
        done
    else
        echo "停止执行。"
        exit 1
    fi

fi
