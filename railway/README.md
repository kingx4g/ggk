# Railway Deploy — نسخه‌ی فنی (خلاصه)

اگه با Railway و ترمینال راحتی و نمی‌خوای راهنمای گام‌به‌گام بخونی، خلاصه‌ش اینه:

1. فایل `railway-compose.yml` رو بکش و روی صفحه‌ی یک پروژه‌ی خالی توی Railway رها کن → Deploy بزن
2. مقدار `RAILWAY_PRIVATE_DOMAIN` سرویس `node` رو از تب Variables بردار
3. اجرا کن: `bash scripts/railway-cert.sh <همون مقدار>`
4. خروجی `SSL_CERT_B64` و `SSL_KEY_B64` رو روی سرویس `node` ست کن و Redeploy بزن
5. روی سرویس‌های `proxy` (پورت 8080) و `node` (پورت 8880) از Settings → Networking یک Public Domain بساز
6. از Deploy Logs سرویس panel، کلید موقت `generate-temp-key` رو بردار و از دکمه‌ی «دسترسی مالک» توی پنل اکانت مالک بساز
7. نود رو توی پنل با Address/Port/API Key/Certificate اضافه کن
8. اینباندهای نمونه‌ی `inbounds/*.json` رو توی Core Config پنل ست کن

راهنمای کامل و بدون فرض دانش فنی: `START-HERE.md`

## چرا این تنظیمات لازمه؟

- **پسورد دیتابیس، گواهی پنل، API Key نود**: از قبل توی `railway-compose.yml` تولید و جاسازی شدن
- **گواهی node رو نمیشه از قبل ساخت** چون CN/SAN گواهی باید دقیقاً برابر `RAILWAY_PRIVATE_DOMAIN` باشه که فقط بعد از ساخته‌شدن سرویس مشخص میشه
- **سرویس proxy (Caddy)** لازمه چون Railway همیشه با HTTP ساده به کانتینر وصل میشه ولی پنل فقط HTTPS قبول می‌کنه
- **اینباند WS+TLS به‌جای Reality** چون روی پورت واقعی ۴۴۳ با گواهی معتبر Railway کار می‌کنه، نه پورت رندوم TCP Proxy که ممکنه ISP بلاکش کنه
