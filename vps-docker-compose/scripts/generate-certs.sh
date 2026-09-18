#!/usr/bin/env bash
# می‌سازه گواهی‌های خودامضای لازم برای پنل و نود.
# اجرا: bash scripts/generate-certs.sh
# نکته: چون پنل و نود توی همین docker-compose با نام سرویس "node" به هم وصل میشن،
# CN/SAN گواهی نود رو دقیقاً "node" می‌ذاریم (همون هاست‌نیمی که پنل برای وصل‌شدن استفاده می‌کنه).

set -e
cd "$(dirname "$0")/.."

mkdir -p certs/panel certs/node

if [ -f certs/panel/ssl_cert.pem ] && [ -f certs/node/ssl_cert.pem ]; then
  echo "گواهی‌ها از قبل وجود دارن؛ اگه می‌خوای دوباره بسازی، اول پوشه‌ی certs/ رو پاک کن."
  exit 0
fi

echo "در حال ساخت گواهی پنل..."
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout certs/panel/ssl_key.pem -out certs/panel/ssl_cert.pem \
  -subj "/CN=panel" 2>/dev/null

echo "در حال ساخت گواهی نود (CN/SAN = node)..."
cat > /tmp/node_ext.cnf << 'EOF'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = node

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = node
EOF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout certs/node/ssl_key.pem -out certs/node/ssl_cert.pem \
  -config /tmp/node_ext.cnf -extensions v3_req 2>/dev/null

rm -f /tmp/node_ext.cnf

echo ""
echo "✅ گواهی‌ها ساخته شدن:"
echo "   certs/panel/ssl_cert.pem  و  certs/panel/ssl_key.pem"
echo "   certs/node/ssl_cert.pem   و  certs/node/ssl_key.pem"
echo ""
echo "محتوای certs/node/ssl_cert.pem رو موقع اضافه‌کردن Node توی پنل"
echo "(فیلد Certificate) عیناً پیست کن. Address نود رو هم بذار: node   Port: 62050"
