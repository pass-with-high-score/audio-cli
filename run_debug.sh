#!/usr/bin/env bash
set -e

# Script để chạy app trong môi trường phát triển / debug
# Có thể truyền trực tiếp tham số vào script này
# VD: ./run_debug.sh ./nhac_cua_toi -shuffle

if [ -z "$1" ]; then
  echo "⚠️ Usage: ./run_debug.sh <file or directory> [-shuffle] [-loop]"
  exit 1
fi

echo "🔧 Đang khởi động audio-cli..."

# Chạy trực tiếp mã nguồn bằng 'go run'. 
# Flag '-race' giúp phát hiện các lỗi tranh chấp dữ liệu (data race) khi chạy đa luồng (âm thanh, UI)
go run -race ./cmd/audio-cli "$@"
