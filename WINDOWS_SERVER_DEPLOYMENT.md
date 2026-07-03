# Windows Server EC2 Deployment Guide

## ⚠️ IMPORTANT: You're Using Windows Server, Not Linux!

This changes deployment completely.

**Connection Method:**
- ❌ SSH (for Linux)
- ✅ **RDP - Remote Desktop Protocol** (for Windows)

---

## STEP 1: Get Windows Administrator Password

Your PEM key is used to **decrypt** the Windows admin password.

### On Windows using EC2 Console:

1. Open: https://ap-south-1.console.aws.amazon.com/ec2/instances/

2. Find **Dipanddash** instance

3. Right-click → **Connect**

4. Go to **RDP client** tab

5. Click **Download remote desktop file**

6. Click **Get password**

7. Upload your PEM file:
   - Browse to: `C:\DipandDashbackend\food\Dipanddash.pem`
   - Click **Decrypt password**

8. Copy the decrypted password (save it somewhere safe)

---

## STEP 2: Connect via Remote Desktop

### Using Windows Remote Desktop:

1. Press `Windows Key + R`

2. Type: `mstsc`

3. Click **OK** (Opens Remote Desktop Connection)

4. Paste your instance IP: `13.235.27.182`

5. Click **Connect**

6. Username: `Administrator`

7. Password: (the decrypted password from Step 1)

8. Click **OK**

9. Choose: Yes, to accept the certificate

10. ✅ You're now connected to Windows Server!

---

## STEP 3: Install Prerequisites on Windows Server

Once connected via RDP, run these commands in **PowerShell (as Administrator)**:

```powershell
# Open PowerShell as Administrator
# Right-click PowerShell → Run as administrator

# Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python
choco install python -y

# Install Git
choco install git -y

# Close and reopen PowerShell for PATH changes
exit
```

---

## STEP 4: Upload Your Django Project

### Option A: Using Remote Desktop File Transfer

1. In RDP Connection → Options → Local Resources → More

2. Enable: Drives or folders to share

3. Select your project folder: `C:\DipandDashbackend\food`

4. Once connected, open explorer on Windows Server

5. Navigate to: `This PC → D: Drive` (or mapped drive)

6. Copy your project to: `C:\Projects\dipanddash`

### Option B: Using Git

```powershell
# If you have a GitHub repo
cd C:\
mkdir Projects
cd Projects
git clone https://github.com/your-repo/food.git
cd food
```

### Option C: Upload via Azure File Share (Advanced)

---

## STEP 5: Setup Django on Windows Server

```powershell
cd C:\Projects\dipanddash

# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# If you get execution policy error:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Try activation again
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Or manually install:
pip install Django djangorestframework django-cors-headers djangorestframework-simplejwt psycopg2-binary gunicorn pillow python-decouple

# Create .env file
$env_content = @"
DEBUG=False
SECRET_KEY=your-secret-key-change-this
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost

DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432

CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000
CSRF_TRUSTED_ORIGINS=http://13.235.27.182,http://localhost:3000
CSRF_COOKIE_SECURE=False
SESSION_COOKIE_SECURE=False
"@

$env_content | Out-File -FilePath ".env" -Encoding UTF8

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser (optional)
# python manage.py createsuperuser
```

---

## STEP 6: Setup Gunicorn on Windows

```powershell
# Install waitress (better for Windows than Gunicorn)
pip install waitress

# Test run (will block terminal)
waitress-serve --port=8000 food.wsgi:application

# Press Ctrl+C to stop
```

---

## STEP 7: Setup IIS (Optional - For Production)

Or use **NSSM** (Non-Sucking Service Manager) to run as a Windows Service:

```powershell
# Install NSSM
choco install nssm -y

# Create service
nssm install dipanddash-server "C:\Projects\dipanddash\venv\Scripts\waitress-serve.exe" "--port=8000 food.wsgi:application"

# Start service
nssm start dipanddash-server

# Stop service
nssm stop dipanddash-server

# View logs
nssm get dipanddash-server AppEvents
```

---

## STEP 8: Update Windows Firewall

```powershell
# Open port 8000 for Django
New-NetFirewallRule -DisplayName "Allow Django 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow

# Open port 80 for HTTP
New-NetFirewallRule -DisplayName "Allow HTTP 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

# Open port 443 for HTTPS
New-NetFirewallRule -DisplayName "Allow HTTPS 443" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
```

---

## STEP 9: Access Your API

Your API will be available at: `http://13.235.27.182:8000`

---

## Useful Commands

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Deactivate virtual environment
deactivate

# Run Django development server
python manage.py runserver 0.0.0.0:8000

# Run Gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 food.wsgi:application

# Run Waitress (recommended for Windows)
waitress-serve --port=8000 food.wsgi:application

# Check Python version
python --version

# Check pip packages
pip list

# View NSSM service
nssm query dipanddash-server
```

---

## Summary: Windows vs Linux Differences

| Task | Linux (Ubuntu) | Windows Server |
|------|---|---|
| **Connection** | SSH | RDP (Remote Desktop) |
| **Port** | 22 | 3389 |
| **Shell** | Bash | PowerShell |
| **Package Manager** | apt | Chocolatey |
| **Virtual Env** | python3 -m venv | python -m venv |
| **Run** | ./venv/bin/activate | .\venv\Scripts\Activate.ps1 |
| **Service Manager** | Supervisor/systemd | NSSM/Windows Service |
| **Web Server** | Nginx | IIS or Waitress |
| **Firewall** | iptables | Windows Firewall |

---

## Deploy Checklist (Windows Server)

- [ ] Connected to Windows Server via RDP
- [ ] Installed Python, Git, Chocolatey
- [ ] Uploaded Django project to C:\Projects\dipanddash
- [ ] Created virtual environment
- [ ] Installed Python dependencies
- [ ] Created .env file with credentials
- [ ] Ran python manage.py migrate
- [ ] Ran python manage.py collectstatic
- [ ] Tested with: waitress-serve --port=8000 food.wsgi:application
- [ ] Setup Windows Firewall rules
- [ ] Accessed http://13.235.27.182:8000 in browser
- [ ] Setup NSSM service (optional, for production)

---

**Next Steps:**
1. Get Windows admin password (decrypt PEM key)
2. Connect via RDP
3. Install Python and Git
4. Upload your Django project
5. Follow the setup steps above

Good luck! 🚀
