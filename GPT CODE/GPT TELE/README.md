# ดาวน์โหลดวิดีโอจาก Telegram

ใช้ Python 3.10 ขึ้นไป และบัญชี Telegram ที่มีสิทธิ์เข้าถึงแชต/กลุ่ม/ช่องนั้นอยู่แล้ว รองรับช่องส่วนตัวและ Saved Messages ไม่รองรับ Secret Chat

## เริ่มใช้งานบน Windows (PowerShell)

1. สร้าง API ID และ API hash ที่ https://my.telegram.org ในเมนู API development tools
2. ติดตั้งไลบรารี:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

3. ดูรายการแชตและ ID:

```powershell
.\.venv\Scripts\python.exe telegram_download.py --list-chats
```

โปรแกรมจะถาม API ID, API hash และในการล็อกอินครั้งแรกจะถามเบอร์โทรพร้อมรหัสประเทศ เช่น +66..., รหัสยืนยัน Telegram และรหัสผ่าน Two-Step Verification ถ้าตั้งไว้ กรอกทั้งหมดในเครื่องของคุณ ไม่ต้องส่งมาในแชตนี้ ครั้งต่อไปใช้ session ที่บันทึกไว้ แต่ยังต้องระบุ API ID/hash หรือกำหนดตัวแปรแวดล้อม `TELEGRAM_API_ID` และ `TELEGRAM_API_HASH`

## ตัวอย่าง

ดาวน์โหลดวิดีโอจากลิงก์ข้อความในช่องส่วนตัว (ต้องเป็นสมาชิกอยู่แล้ว):

```powershell
.\.venv\Scripts\python.exe telegram_download.py --link "https://t.me/c/1234567890/123"
```

ดาวน์โหลดวิดีโอใน 100 ข้อความล่าสุดของแชต โดยใช้ ID ที่ได้จาก `--list-chats`:

```powershell
.\.venv\Scripts\python.exe telegram_download.py --chat=-1001234567890 --limit 100
```

ดาวน์โหลดวิดีโอทั้งหมดใน Saved Messages:

```powershell
.\.venv\Scripts\python.exe telegram_download.py --chat me
```

ดาวน์โหลดข้อความเดียวและกำหนดโฟลเดอร์:

```powershell
.\.venv\Scripts\python.exe telegram_download.py --chat=-1001234567890 --message-id 123 --output "D:\TelegramVideos"
```

หากไม่ระบุ `--limit` จะตรวจข้อความทั้งหมด ตัวเลือกนี้นับจำนวนข้อความที่ตรวจ ไม่ใช่จำนวนวิดีโอ โปรแกรมเก็บไฟล์ใน `downloads/<chat_id>/` และเติม ID ข้อความหน้าชื่อไฟล์เพื่อป้องกันชื่อซ้ำ ไฟล์ที่มีขนาดตรงกับต้นฉบับจะถูกข้าม ไฟล์ระหว่างโหลดลงท้าย `.part` หากโหลดขาดให้ลบไฟล์ `.part` นั้นแล้วรันใหม่ (เริ่มวิดีโอนั้นตั้งแต่ต้น)

ไฟล์ใน `.sessions/` ใช้เข้าสู่บัญชีได้ ควรเก็บเป็นความลับและอย่าแชร์ให้ผู้อื่น ดาวน์โหลดเฉพาะเนื้อหาที่คุณมีสิทธิ์บันทึก โปรแกรมไม่ได้เข้าร่วมช่องให้อัตโนมัติหรือข้ามข้อจำกัดการเข้าถึงของ Telegram

อ้างอิง API: [Telethon download_media และ iter_messages](https://docs.telethon.dev/en/stable/modules/client.html)
