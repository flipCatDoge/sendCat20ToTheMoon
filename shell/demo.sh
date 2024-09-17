#!/bin/bash

# 使用如报错请先执行命令 sudo apt-get install jq
# sudo apt-get install curl
# CentOS/RHEL的linux系统，将上方apt-get替换为yum指令
# 信息捕手聚合社区 - 脚本工具 + KOL信息 + 监控工具 全聚合～
# 购买联系客服微信：coecvyy

source ./shell/common.sh
# 自动生成多开的不同路径配置文件
filename=$(basename "$0" .sh)

app "$filename"