"""
FinanceHub Telegram Bot
Kassir xabarlarini o'qib, Claude API orqali parse qilib, Supabase ga saqlaydi.
"""

import os
import json
import uuid
import logging
from datetime import datetime, timezone
from telegram import Update
from telegram.ext import Application, MessageHandler, filters, ContextTypes
import anthropic
from supabase import create_client

# ── Config (Railway/Render da Environment Variables sifatida qo'ying) ──
TELEGRAM_TOKEN   = os.environ["TELEGRAM_BOT_TOKEN"]
ANTHROPIC_KEY    = os.environ["ANTHROPIC_API_KEY"]
SUPABASE_URL     = os.environ["SUPABASE_URL"]
SUPABASE_KEY     = os.environ["SUPABASE_SERVICE_KEY"]  # service_role key (RLS bypass)
ALLOWED_GROUP_ID = int(os.environ.get("TELEGRAM_GROUP_ID", "0"))  # 0 = barcha guruhlar

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# ── Clients ──
ai  = anthropic.Anthropic(api_key=ANTHROPIC_KEY)
sb  = create_client(SUPABASE_URL, SUPABASE_KEY)

# ── Yo'nalish → direction mapping ──
# Kassir "Tangachi" yozsa → "exchange", "Logistics" → "logistics"
DIRECTION_MAP = {
    "tangachi":    "exchange",
    "exchange":    "exchange",
    "ayirboshlash": "exchange",
    "logistics":   "logistics",
    "logistika":   "logistics",
    "cargo":       "cargo",
    "kargo":       "cargo",
    "procurement": "procurement",
    "ta'minot":    "procurement",
    "holding":     "holding",
}

SYSTEM_PROMPT = """Siz FinanceHub moliyaviy tizimi uchun kassir xabarlarini tahlil qiluvchisiz.

Kassir xabaridan quyidagi ma'lumotlarni ajrating va FAQAT JSON qaytaring:

{
  "is_financial": true/false,         // moliyaviy xabar ekanmi
  "type": "income" | "expense",       // kirim yoki chiqim
  "amount": 20000,                    // summa (musbat son)
  "currency": "USD" | "CNY" | "UZS" | "RUB" | "EUR",
  "client": "Olimjon",               // mijoz/kontragent ismi
  "kassa": "tangachi",               // qaysi kassa (kichik harfda)
  "direction": "exchange",           // yo'nalish (exchange/logistics/cargo/procurement/holding)
  "purpose": "yuan uchun",          // maqsad/izoh
  "note": "xabarning to'liq matni"  // original xabar
}

Yo'nalishni aniqlashda kassa nomidan foydalaning:
- tangachi, ayirboshlash → exchange
- logistics, logistika → logistics
- cargo, kargo → cargo
- procurement, ta'minot → procurement

Agar xabar moliyaviy bo'lmasa: {"is_financial": false}
Faqat JSON qaytaring, boshqa hech narsa yozmang."""


async def parse_message(text: str) -> dict | None:
    """Claude API orqali xabarni parse qiladi."""
    try:
        resp = ai.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=512,
            messages=[{"role": "user", "content": text}],
            system=SYSTEM_PROMPT,
        )
        raw = resp.content[0].text.strip()
        # JSON blok ichidan ajratib olish
        if "```" in raw:
            raw = raw.split("```")[1].replace("json", "").strip()
        return json.loads(raw)
    except Exception as e:
        log.error(f"Parse xato: {e}")
        return None


def build_txn(parsed: dict, sender: str) -> dict:
    """FinanceHub TXNS formatida tranzaksiya yaratadi."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    period = today[:7]
    amount = parsed.get("amount", 0)
    txn_type = parsed.get("type", "income")
    signed_amount = abs(amount) if txn_type == "income" else -abs(amount)

    # direction aniqlash
    direction = parsed.get("direction", "")
    kassa_key = (parsed.get("kassa") or "").lower()
    for k, v in DIRECTION_MAP.items():
        if k in kassa_key or k in direction.lower():
            direction = v
            break
    if not direction:
        direction = "holding"

    return {
        "id": "TXN-TG-" + str(uuid.uuid4())[:8].upper(),
        "date": today,
        "period": period,
        "payment_period": period,
        "accrual_period": period,
        "direction": direction,
        "dept": "",
        "type": txn_type,
        "subcat": parsed.get("purpose", ""),
        "amount": signed_amount,
        "currency": parsed.get("currency", "USD"),
        "amount_orig": signed_amount,
        "fx_rate": 1,
        "counterparty": parsed.get("client", ""),
        "purpose": parsed.get("purpose", ""),
        "status": "To'landi",
        "note": f"[Telegram: {sender}] {parsed.get('note', '')}",
        "source": "telegram",
        "kassa": parsed.get("kassa", ""),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


def save_to_supabase(txn: dict):
    """Supabase app_txns ga saqlaydi."""
    row = {
        "id": txn["id"],
        "data": txn,
        "dir": txn["direction"],
        "type": txn["type"],
    }
    sb.table("app_txns").upsert(row, on_conflict="id").execute()


async def handle_message(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    msg = update.message
    if not msg or not msg.text:
        return

    # Guruh filtri
    if ALLOWED_GROUP_ID and msg.chat_id != ALLOWED_GROUP_ID:
        return

    text = msg.text.strip()
    sender = msg.from_user.full_name if msg.from_user else "Noma'lum"

    parsed = await parse_message(text)
    if not parsed or not parsed.get("is_financial"):
        return  # moliyaviy xabar emas — e'tiborsiz qoldirish

    txn = build_txn(parsed, sender)

    try:
        save_to_supabase(txn)
        sign = "📥" if txn["type"] == "income" else "📤"
        reply = (
            f"{sign} *Qabul qilindi!*\n"
            f"💰 {abs(txn['amount']):,.0f} {txn['currency']}\n"
            f"👤 Mijoz: {parsed.get('client', '—')}\n"
            f"🏦 Yo'nalish: {txn['direction']}\n"
            f"📝 Maqsad: {parsed.get('purpose', '—')}\n"
            f"🆔 `{txn['id']}`"
        )
        await msg.reply_text(reply, parse_mode="Markdown")
        log.info(f"Saqlandi: {txn['id']} | {txn['direction']} | {txn['amount']} {txn['currency']}")
    except Exception as e:
        log.error(f"Supabase xato: {e}")
        await msg.reply_text("❌ Xatolik yuz berdi, admin bilan bog'laning.")


def main():
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    log.info("Bot ishga tushdi...")
    app.run_polling()


if __name__ == "__main__":
    main()
