#!/usr/bin/env bash
cd "$(dirname "$0")/.."
if [ ! -f certs/node/ssl_cert.pem ]; then
  echo "گواهی نود پیدا نشد. اول bash setup.sh یا bash scripts/generate-certs.sh رو اجرا کن."
  exit 1
fi
echo "این متن رو توی فیلد Certificate پنل (موقع اضافه‌کردن نود) پیست کن:"
echo ""
cat certs/node/ssl_cert.pem
