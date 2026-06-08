import http.server
import socketserver
import webbrowser
import os
import subprocess
import sys
import time

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    def log_message(self, format, *args):
        pass  # Loglarni yashirish

# ── Logist backend avtomatik ishga tushirish ──────────────────
logist_backend = os.path.join(DIRECTORY, 'Logist', 'Logist', 'backend', 'main.py')
logist_proc = None

if os.path.exists(logist_backend):
    try:
        logist_proc = subprocess.Popen(
            [sys.executable, logist_backend],
            cwd=os.path.dirname(logist_backend),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW if sys.platform=='win32' else 0
        )
        time.sleep(1.5)
        print("  ✅ Logist baza:  http://localhost:8000  (167K+ kompaniya)")
    except Exception as e:
        print(f"  ⚠  Logist ishga tushmadi: {e}")
else:
    print("  ⚠  Logist backend topilmadi (Logist\\Logist\\backend\\main.py)")

print("=" * 52)
print("  FinanceHub — Lokal Server")
print(f"  http://localhost:{PORT}/financehub-v9.html")
print("  To'xtatish uchun: Ctrl+C")
print("=" * 52)

webbrowser.open(f"http://localhost:{PORT}/financehub-v9.html")

try:
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    if logist_proc:
        logist_proc.terminate()
        print("\n  Logist baza to'xtatildi.")
    print("  FinanceHub to'xtatildi.")
