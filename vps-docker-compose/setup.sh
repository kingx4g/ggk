#!/usr/bin/env bash
# راه‌اندازی کامل PasarGuard (Panel + Node) با یک دستور.
# استفاده:
#   bash setup.sh

set -e
cd "$(dirname "$0")"

if ! command -v docker &> /dev/null; then
  echo "❌ داکر نصب نیست. اول Docker و Docker Compose رو نصب کن:"
  echo "   curl -fsSL https://get.docker.com | sh"
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  RANDOM_PASS=$(openssl rand -hex 16)
  RANDOM_UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
  sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${RANDOM_PASS}/" .env
  sed -i "s/NODE_API_KEY=.*/NODE_API_KEY=${RANDOM_UUID}/" .env
  echo "✅ فایل .env با پسورد و API Key رندوم ساخته شد."
  echo "   اگه دامنه داری و می‌خوای از Caddy با گواهی معتبر استفاده کنی، PANEL_DOMAIN رو توی .env ویرایش کن."
  echo ""
fi

set -a
source .env
set +a

echo "در حال ساخت گواهی‌های SSL..."
bash scripts/generate-certs.sh

echo ""
echo "در حال بالا آوردن سرویس‌ها (ممکنه چند دقیقه طول بکشه)..."
docker compose up -d postgres
echo "منتظر آماده شدن دیتابیس..."
sleep 8
docker compose up -d panel node

if [ -n "$PANEL_DOMAIN" ]; then
  docker compose up -d caddy
fi

echo ""
echo "منتظر بالا اومدن کامل پنل..."
sleep 8

echo ""
echo "در حال ساخت کلید موقت برای اکانت مالک (owner)..."
docker compose exec -T panel python pasarguard-cli.py generate-temp-key || true

echo ""
echo "================================================================"
echo "✅ همه‌چیز بالا اومد!"
echo ""
if [ -n "$PANEL_DOMAIN" ]; then
  echo "🔗 آدرس پنل: https://${PANEL_DOMAIN}/dashboard/"
else
  echo "🔗 آدرس پنل: https://<IP-سرور>:8000/dashboard/"
  echo "   (چون گواهی خودامضاست، مرورگر هشدار میده — روی Advanced > Proceed بزن)"
fi
echo ""
echo "کلید موقت مالک همین بالا چاپ شد (فقط ۵ دقیقه اعتبار داره)."
echo "توی صفحه‌ی لاگین روی «دسترسی مالک / Owner Access» بزن و اون کلید رو وارد کن."
echo ""
echo "برای اضافه‌کردن نود توی پنل:"
echo "   Address : node"
echo "   Port    : 62050"
echo "   API Key : ${NODE_API_KEY}"
echo "   Certificate : محتوای فایل certs/node/ssl_cert.pem (با bash scripts/show-node-cert.sh می‌تونی ببینیش)"
echo ""
echo "نمونه‌ی اینباندها رو توی پوشه‌ی inbounds/ بذار داخل Core Config پنل."
echo "================================================================"
