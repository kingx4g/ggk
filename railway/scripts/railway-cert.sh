#!/usr/bin/env bash
# مخصوص فلوی Railway: یه گواهی خودامضا می‌سازه و مستقیم مقادیر base64
# آماده‌ی پیست توی Railway Variables رو چاپ می‌کنه.
#
# استفاده برای پنل (که هاست‌نیمش مهم نیست، هر CN ای کافیه):
#   bash scripts/railway-cert.sh panel
#
# استفاده برای نود (باید دقیقاً برابر RAILWAY_PRIVATE_DOMAIN سرویس node باشه،
# که از تب Variables همون سرویس توی داشبورد Railway کپی می‌کنی):
#   bash scripts/railway-cert.sh node.railway.internal

set -e
HOSTNAME="${1:?"استفاده: bash scripts/railway-cert.sh <hostname>   (مثلاً panel یا node.railway.internal)"}"

TMPDIR=$(mktemp -d)
cat > "$TMPDIR/ext.cnf" << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${HOSTNAME}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME}
EOF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMPDIR/key.pem" -out "$TMPDIR/cert.pem" \
  -config "$TMPDIR/ext.cnf" -extensions v3_req 2>/dev/null

echo "================================================================"
echo "برای هاست‌نیم: ${HOSTNAME}"
echo "================================================================"
echo ""
echo "--- مقدار *_CERT_B64 (پیست توی Railway Variables) ---"
base64 -w0 "$TMPDIR/cert.pem"
echo ""
echo ""
echo "--- مقدار *_KEY_B64 (پیست توی Railway Variables) ---"
base64 -w0 "$TMPDIR/key.pem"
echo ""
echo ""
echo "--- اگه این گواهی نوده، این متن رو توی فیلد Certificate پنل هم پیست کن ---"
cat "$TMPDIR/cert.pem"

rm -rf "$TMPDIR"
