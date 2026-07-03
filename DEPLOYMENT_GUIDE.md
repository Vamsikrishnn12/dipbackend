# Django Backend Deployment Guide for AWS EC2

## EC2 Instance Details
- **IP Address:** `13.235.27.182`
- **DNS:** `ec2-13-235-27-182.ap-south-1.compute.amazonaws.com`
- **Region:** ap-south-1 (Mumbai)
- **Instance Type:** t3.small
- **OS:** Amazon Linux 2 or Ubuntu (verify before proceeding)
- **Key File:** `Dipanddash.pem`

---

## Step 1: Prepare Your Local Machine (Windows)

### Option A: Using Windows Subsystem for Linux (WSL) / Git Bash
```bash
# Set correct permissions for the PEM file
chmod 400 Dipanddash.pem
```

### Option B: Using PuTTY (Windows SSH Client)
1. Download PuTTY and PuTTYgen
2. Convert `.pem` to `.ppk` format using PuTTYgen
3. Save as `Dipanddash.ppk`

---

## Step 2: Connect to EC2 Instance

### Using PowerShell/Git Bash:
```bash
ssh -i "Dipanddash.pem" ubuntu@13.235.27.182
```

**Default usernames by OS:**
- Ubuntu: `ubuntu`
- Amazon Linux 2: `ec2-user`

**If you get "Permission denied" error:**
```bash
# Windows (PowerShell as Admin)
icacls.exe "Dipanddash.pem" /reset
icacls.exe "Dipanddash.pem" /grant:r "$($env:USERNAME):(F)"
ssh -i "Dipanddash.pem" ubuntu@13.235.27.182
```

---

## Step 3: Initial Setup on EC2

Once connected to EC2, run these commands:

```bash
# Update and install basic tools
sudo apt-get update && sudo apt-get upgrade -y

# Install Python and dependencies
sudo apt-get install -y python3.10 python3.10-venv python3-pip build-essential libpq-dev

# Create application directory
sudo mkdir -p /var/www/dipanddash
sudo chown -R ubuntu:ubuntu /var/www/dipanddash
cd /var/www/dipanddash
```

---

## Step 4: Upload Your Project Files

### Option A: Using SCP (Secure Copy)
From your local machine (Windows Command Prompt or PowerShell):

```bash
cd C:\DipandDashbackend

# Copy the entire project
scp -i "food\Dipanddash.pem" -r food ubuntu@13.235.27.182:/var/www/dipanddash/
```

### Option B: Using Git
If you have a GitHub repository:

```bash
cd /var/www/dipanddash
git clone https://github.com/your-repo/food.git
cd food
git switch main  # or your branch name
```

### Option C: Manual File Transfer
1. Use FileZilla or WinSCP
2. Connect with SFTP using your PEM key
3. Upload files to `/var/www/dipanddash/food`

---

## Step 5: Setup Django Application

On your EC2 instance, run:

```bash
cd /var/www/dipanddash/food

# Create virtual environment
python3.10 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create logs directory
mkdir -p /var/www/dipanddash/logs

# Create .env file (update with your actual values)
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=your-very-secret-key-here-change-this
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost

# Database (Neon PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432

CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000
EOF

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Create superuser (optional)
# python manage.py createsuperuser
```

---

## Step 6: Update Django Settings

Edit your settings.py to include:

```python
# settings.py

import os
from pathlib import Path
from decouple import config

# Load environment variables
DEBUG = config('DEBUG', default=False, cast=bool)
SECRET_KEY = config('SECRET_KEY', default='dev-secret-key')
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost').split(',')

# Database Configuration
DATABASES = {
    'default': {
        'ENGINE': config('DB_ENGINE', default='django.db.backends.postgresql'),
        'NAME': config('DB_NAME', default='neondb'),
        'USER': config('DB_USER', default='neondb_owner'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT', default='5432'),
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

# CORS Settings
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='http://localhost:3000').split(',')

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

---

## Step 7: Setup Supervisor (Process Management)

Supervisor will automatically restart your Django app if it crashes.

```bash
# Create supervisor config
sudo mkdir -p /etc/supervisor/conf.d
sudo tee /etc/supervisor/conf.d/dipanddash.conf > /dev/null << 'EOF'
[program:dipanddash]
directory=/var/www/dipanddash/food
command=/var/www/dipanddash/food/venv/bin/gunicorn -w 4 -b 127.0.0.1:8000 food.wsgi:application
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/www/dipanddash/logs/gunicorn.log
environment=PATH="/var/www/dipanddash/food/venv/bin",DJANGO_SETTINGS_MODULE="food.settings"
EOF

# Start supervisor
sudo systemctl start supervisor
sudo systemctl enable supervisor

# Start your application
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start dipanddash

# Check status
sudo supervisorctl status
```

---

## Step 8: Setup Nginx (Reverse Proxy)

```bash
# Create nginx config
sudo tee /etc/nginx/sites-available/dipanddash > /dev/null << 'EOF'
upstream dipanddash_backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name 13.235.27.182 ec2-13-235-27-182.ap-south-1.compute.amazonaws.com;
    client_max_body_size 20M;

    access_log /var/log/nginx/dipanddash_access.log;
    error_log /var/log/nginx/dipanddash_error.log;

    location /static/ {
        alias /var/www/dipanddash/food/staticfiles/;
        expires 7d;
    }

    location /media/ {
        alias /var/www/dipanddash/food/media/;
        expires 7d;
    }

    location / {
        proxy_pass http://dipanddash_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable nginx config
sudo ln -s /etc/nginx/sites-available/dipanddash /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test nginx config
sudo nginx -t

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Restart nginx
sudo systemctl restart nginx
```

---

## Step 9: Check Security Group

**Important:** Update your EC2 Security Group to allow traffic:

1. Go to EC2 Dashboard → Security Groups
2. Find the security group for your instance
3. Add **Inbound Rules:**
   - **Type:** SSH, **Port:** 22, **Source:** Your IP
   - **Type:** HTTP, **Port:** 80, **Source:** 0.0.0.0/0
   - **Type:** HTTPS, **Port:** 443, **Source:** 0.0.0.0/0

---

## Step 10: Test Your Deployment

```bash
# Check if Gunicorn is running
curl http://127.0.0.1:8000

# Check Nginx
curl http://13.235.27.182

# View logs
tail -f /var/www/dipanddash/logs/gunicorn.log
tail -f /var/log/nginx/error.log
sudo supervisorctl tail dipanddash
```

---

## Useful Commands

```bash
# View application logs
sudo supervisorctl tail dipanddash

# Restart application
sudo supervisorctl restart dipanddash

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx status
sudo systemctl status nginx

# Stop application
sudo supervisorctl stop dipanddash

# SSH into EC2
ssh -i "Dipanddash.pem" ubuntu@13.235.27.182

# Update application (after git pull)
cd /var/www/dipanddash/food
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo supervisorctl restart dipanddash
```

---

## Troubleshooting

### Connection Issues
```bash
# Check if EC2 is running
# Verify Security Group rules allow SSH on port 22
# Verify PEM file permissions: chmod 400 Dipanddash.pem
```

### Django Not Starting
```bash
sudo supervisorctl tail dipanddash -n 100  # Last 100 lines
python manage.py check  # Verify Django settings
```

### Database Connection Error
```bash
# Test PostgreSQL connectivity
psql -h ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech -U neondb_owner -d neondb -c "SELECT 1"
```

### Nginx Not Working
```bash
sudo nginx -t  # Test config syntax
sudo systemctl restart nginx
sudo tail -f /var/log/nginx/error.log
```

---

## Next Steps: Setup SSL Certificate (HTTPS)

Install Certbot for Let's Encrypt SSL:

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ec2-13-235-27-182.ap-south-1.compute.amazonaws.com
sudo systemctl restart nginx
```

---

**Your API will be available at:** `http://13.235.27.182`

Happy deploying! 🚀
