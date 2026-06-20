#!/bin/bash

# SwiftLint 自动运行脚本
# 用于开发时自动检查代码质量

echo "🔍 正在运行 SwiftLint 检查..."

# 运行 SwiftLint
if swiftlint lint; then
    echo "✅ SwiftLint 检查完成，没有发现问题"
    exit 0
else
    echo "⚠️ SwiftLint 检查发现警告，请查看上方详情"
    exit 1
fi
