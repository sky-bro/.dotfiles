#!/bin/bash

# 检查参数数量是否正确
if [ $# -lt 2 ]; then
    echo "Usage: $0 <source1> [source2 ...] <destination>"
    exit 1
fi

# 获取最后一个参数作为目标文件夹
destination="${@: -1}"

# 获取所有源文件/文件夹
sources=("${@:1:$#-1}")

# 持续检查源文件/文件夹和目标文件夹是否存在
while true; do
    all_exist=true

    # 检查所有源文件/文件夹是否存在
    for source in "${sources[@]}"; do
        if [ ! -e "$source" ]; then
            all_exist=false
            break
        fi
    done

    # 检查目标文件夹是否存在
    if [ ! -d "$destination" ]; then
        all_exist=false
    fi

    # 如果所有条件都满足，则执行复制操作并退出循环
    if $all_exist; then
        cp -r "${sources[@]}" "$destination"
        echo "Copy operation completed."
        break
    else
        echo "Waiting for sources and destination to exist..."
        sleep 1
    fi
done
