# Windows Server EC2 - Quick Start

## Your Setup
- **OS:** Windows Server (not Linux)
- **Connection:** RDP (Remote Desktop), NOT SSH
- **IP:** 13.235.27.182
- **Port:** 3389 (RDP)
- **PEM Key:** Dipanddash.pem (to decrypt admin password)

---

## 3 QUICK STEPS ⚡

### STEP 1: Decrypt Admin Password (3 minutes)

1. Go to: https://ap-south-1.console.aws.amazon.com/ec2/instances/

2. Click **Dipanddash** instance

3. Click **Connect** button (top right)

4. Go to **RDP client** tab

5. Click **Download remote desktop file**

6. Back on same page, click **Get password**

7. Click **Browse** and select:
   `C:\DipandDashbackend\food\Dipanddash.pem`

8. Click **Decrypt password**

9. **Copy the password** (save it!)

---

### STEP 2: Connect via Remote Desktop (2 minutes)

1. Press: `Windows Key + R`

2. Type: `mstsc`

3. Enter IP: `13.235.27.182`

4. Click **Connect**

5. Username: `Administrator`

6. Password: (paste from Step 1)

7. Click **OK** → **Yes** (accept certificate)

8. ✅ You're in Windows Server!

---

### STEP 3: Deploy Django (10 minutes)

Once inside Windows Server, open **PowerShell as Administrator** and run:

```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python & Git
choco install python git -y

# Close PowerShell, open new one as Admin

# Create project folder
mkdir C:\Projects
cd C:\Projects

# Option A: Clone from GitHub (if you have repo)
git clone https://github.com/your-repo/food.git
cd food

# Option B: Or copy your local project files to C:\Projects\dipanddash\

# Setup Django
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Create .env file (with your actual credentials)
@"
DEBUG=False
SECRET_KEY=change-me-to-random-key
ALLOWED_HOSTS=13.235.27.182,localhost
DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432
CORS_ALLOWED_ORIGINS=http://13.235.27.182
"@ | Out-File .env -Encoding UTF8

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Test run (press Ctrl+C to stop)
pip install waitress
waitress-serve --port=8000 food.wsgi:application
```

✅ **Your API is now at:** `http://13.235.27.182:8000`

---

## Open Windows Firewall

In PowerShell (Admin), open port 8000:

```powershell
New-NetFirewallRule -DisplayName "Allow Django 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

---

## Differences from Linux

| Feature | Linux (Ubuntu) | Windows Server |
|---------|---|---|
| Connection | SSH (port 22) | RDP (port 3389) |
| Shell | Bash | PowerShell |
| Virtual Env Activate | `source venv/bin/activate` | `.\venv\Scripts\Activate.ps1` |
| Run Server | `gunicorn` | `waitress-serve` |

---

## Full Documentation

Read: **WINDOWS_SERVER_DEPLOYMENT.md** for detailed setup

---

**Ready?** Start with Step 1: Decrypt admin password! 🚀
