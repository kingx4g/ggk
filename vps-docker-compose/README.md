# PasarGuard — نصب روی VPS با Docker Compose

این پوشه مخصوص نصب PasarGuard (پنل + نود) روی یک سرور لینوکسی خودت (VPS) هست — **نه Railway**. اگه می‌خوای روی Railway دیپلوی کنی، این پوشه رو نادیده بگیر و برو سراغ پوشه‌ی `../railway/`.

## پیش‌نیاز

- یک سرور لینوکسی (VPS) با Docker و Docker Compose نصب‌شده
  - اگه نصب نیست: `curl -fsSL https://get.docker.com | sh`
- (اختیاری) یک دامنه که به IP سرور اشاره کنه، اگه می‌خوای پنل با گواهی معتبر SSL بالا بیاد

## نصب سریع

```bash
cd vps-docker-compose
bash setup.sh
```

همین. اسکریپت خودش:
1. یک فایل `.env` با پسورد و API Key رندوم می‌سازه
2. گواهی‌های SSL لازم برای پنل و نود رو می‌سازه (با تنظیمات درست، از جمله SAN صحیح که پنل بدون خطای Hostname mismatch بتونه به نود وصل بشه)
3. Postgres، پنل، و نود رو بالا میاره
4. اگه `PANEL_DOMAIN` رو توی `.env` پر کرده باشی، یک Caddy هم بالا میاره که با گواهی معتبر Let's Encrypt پنل رو در دسترس می‌ذاره
5. یک کلید موقت برای ساخت اکانت مالک (owner) می‌سازه و نشونت میده

در آخر اجرا، آدرس پنل و کلید موقت رو بهت نشون میده.

## بعد از اجرای اسکریپت

### ۱. ساخت اکانت مالک

آدرس پنل رو باز کن، روی دکمه‌ی **«دسترسی مالک»** بزن، کلید موقتی که اسکریپت چاپ کرد رو وارد کن، و یوزرنیم/پسورد نهایی خودت رو بساز.

> کلید موقت فقط ۵ دقیقه اعتباره. اگه دیر شد، دوباره بساز:
> ```bash
> docker compose exec panel python pasarguard-cli.py generate-temp-key
> ```

### ۲. اضافه‌کردن نود

توی پنل → Nodes → Add Node:

| فیلد | مقدار |
|---|---|
| Address | `node` |
| Port | `62050` |
| API Key | مقدار `NODE_API_KEY` توی فایل `.env` |
| Certificate | خروجی `bash scripts/show-node-cert.sh` |

### ۳. اضافه‌کردن اینباند

توی پنل → Core Settings → ویرایش Core Config، محتوای `inbounds/ws-tls.json` رو به آرایه‌ی `inbounds` اضافه کن.

اگه می‌خوای اینباند Reality هم داشته باشی (`inbounds/reality.json`)، اول کلیدهاش رو بساز:
```bash
pip install cryptography
python3 scripts/generate-reality-keys.py
```
و مقادیر `privateKey` و `shortIds` رو توی فایل جایگزین کن.

### ۴. باز کردن پورت‌های اینباند به بیرون

توی `docker-compose.yml`، پورت‌های `8443` (Reality) و `8880` (WS) از قبل به بیرون باز شدن. برای WS+TLS بهتره یک دامنه/ساب‌دامنه‌ی جدا برای نود هم بذاری پشت Caddy تا با گواهی معتبر روی پورت ۴۴۳ در دسترس باشه (به‌جای دسترسی مستقیم به ۸۸۸۰).

## ساختار پوشه

```
vps-docker-compose/
├── docker-compose.yml       # تعریف همه‌ی سرویس‌ها
├── Caddyfile                # پیکربندی Caddy (اختیاری، برای گواهی معتبر)
├── setup.sh                 # اسکریپت اصلی نصب یک‌مرحله‌ای
├── .env.example             # نمونه‌ی متغیرهای محیطی
├── scripts/
│   ├── generate-certs.sh        # ساخت گواهی خودامضا برای پنل و نود
│   ├── generate-reality-keys.py # ساخت کلید Reality
│   └── show-node-cert.sh        # نمایش گواهی نود برای پیست در پنل
└── inbounds/
    ├── reality.json          # نمونه اینباند VLESS+Reality
    └── ws-tls.json            # نمونه اینباند VLESS+WS(+TLS)
```

## چرا این تنظیمات؟

- **چرا پنل به گواهی SSL نیاز داره؟** نسخه‌ی جدید PasarGuard اگه گواهی نداشته باشه فقط روی `localhost` بایند میشه، نه `0.0.0.0`. `UVICORN_SSL_CA_TYPE=private` هم لازمه چون وگرنه گواهی خودامضا رو رد می‌کنه.
- **چرا `PGDATA` رو جدا تنظیم کردیم؟** بعضی پلتفرم‌ها داخل Volume یک پوشه‌ی `lost+found` می‌سازن که باعث کرش initdb میشه؛ گذاشتن PGDATA روی یک زیرپوشه این مشکل رو حل می‌کنه.
- **چرا گواهی نود باید CN/SAN دقیق داشته باشه؟** پنل هنگام وصل‌شدن به نود، هاست‌نیم گواهی رو با آدرسی که براش گذاشتی چک می‌کنه؛ اگه یکی نباشه با خطای `Hostname mismatch` رد میشه.
- **چرا env-based login (`SUDO_USERNAME`/`SUDO_PASSWORD`) کار نکرد؟** نسخه‌ی جدید PasarGuard این روش رو در حالت production غیرفعال کرده؛ باید از CLI (`generate-temp-key`) و دکمه‌ی «دسترسی مالک» استفاده کنی.
- **چرا دو تا اینباند (Reality و WS+TLS) پیشنهاد شده؟** پورت‌های رندوم/غیرمعمول توسط بعضی ISPها بلاک/throttle میشن. WS+TLS روی پورت واقعی ۴۴۳ با گواهی معتبر خیلی سخت‌تر شناسایی میشه.

## عیب‌یابی سریع

| علامت | احتمالاً چیه |
|---|---|
| `docker compose logs postgres` نشون میده initdb کرش کرده | `PGDATA` درست ست نشده یا Volume قبلی خرابه (`docker compose down -v` و دوباره امتحان کن) |
| پنل بالا نمیاد / 502 | لاگ پنل رو ببین: `docker compose logs panel` |
| لاگین با admin/پسورد ست‌شده در `.env` رد میشه | طبیعیه — باید از روش «دسترسی مالک» با کلید موقت استفاده کنی |
| نود توی پنل قرمز/Error هست | `Check Status` بزن و پیام خطا رو بخون؛ اگه Hostname mismatch بود، گواهی نود رو دوباره بساز |
| کلاینت وصل نمیشه (timeout) | اگه از Reality استفاده می‌کنی، پورتش رو تست کن؛ اگه بلاک بود، از inbound WS+TLS استفاده کن |
