# FinanceHub Telegram Bot

Kassir xabarlarini Telegram guruhidan o'qib, FinanceHub Kassaga avtomatik yozadi.

## Ishga tushirish (Railway.app — BEPUL)

### 1. Telegram Bot yaratish
1. Telegram da @BotFather ga yozing
2. `/newbot` → nom bering → token oling
3. Botni guruhga qo'shing va admin qiling

### 2. Guruh ID olish
1. @userinfobot ni guruhga qo'shing
2. Istalgan xabar yozing → guruh ID ni oling (masalan: `-1001234567890`)
3. @userinfobot ni guruhdan chiqaring

### 3. Supabase Service Key olish
- Supabase → Settings → API → `service_role` key (bu RLS ni chetlab o'tadi)

### 4. Railway.app da deploy
1. railway.app → New Project → Deploy from GitHub
2. `tg_bot/` papkasini repo ga push qiling
3. Environment Variables qo'shing:

```
TELEGRAM_BOT_TOKEN=7123456789:AAF...
ANTHROPIC_API_KEY=sk-ant-...
SUPABASE_URL=https://khgnirqhuyswjmxxkonc.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGci...  (service_role key!)
TELEGRAM_GROUP_ID=-1001234567890
```

5. Start command: `python bot.py`

## Kassir xabar namunalari

Bot quyidagi xabarlarni avtomatik taniydi:

```
Tangachi kassasiga Olimjon dan 20 000 $ oldim yuan uchun
Logistics kassasidan Sarvar uchun yoqilg'i uchun 500 $ berdim
Exchange ga Karim nomli mijozdan 15 000 CNY keldik
Procurement kassasiga 3 500 $ kirim bo'ldi asbob-uskuna uchun
```

Bot javob beradi:
```
📥 Qabul qilindi!
💰 20,000 USD
👤 Mijoz: Olimjon
🏦 Yo'nalish: exchange
📝 Maqsad: yuan uchun
🆔 TXN-TG-A1B2C3D4
```

## FinanceHub da ko'rish

Login → Kassa tab → tranzaksiyalar ro'yxatida ko'rinadi
(Supabase → app_txns → FinanceHub sync)
