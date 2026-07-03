# 🚀 EC2 Deployment Files Summary

## Your EC2 Instance Details
```
IP Address: 13.235.27.182
DNS: ec2-13-235-27-182.ap-south-1.compute.amazonaws.com
Region: ap-south-1 (Mumbai)
Instance Type: t3.small
OS: Ubuntu (based on default user 'ubuntu')
Key File: Dipanddash.pem
```

---

## 📁 Files Created for Deployment

### 1. **DEPLOYMENT_CHECKLIST.md** ⭐ START HERE
**Purpose:** Quick step-by-step commands to deploy
**Use:** Copy-paste commands to deploy your app

### 2. **DEPLOYMENT_GUIDE.md**
**Purpose:** Comprehensive deployment documentation
**Use:** Reference guide with detailed explanations

### 3. **requirements.txt**
**Purpose:** Python dependencies for Django
**Use:** `pip install -r requirements.txt` on EC2

### 4. **deploy-setup.sh**
**Purpose:** Initial system setup on EC2 (optional)
**Use:** Sets up Python, Nginx, Supervisor, etc.

### 5. **deploy-app.sh**
**Purpose:** Deploy application on EC2 (optional)
**Use:** Automates uploading and setting up app

### 6. **gunicorn_config.py**
**Purpose:** Gunicorn WSGI server configuration
**Use:** Reference for Gunicorn setup

### 7. **nginx_config.conf**
**Purpose:** Nginx reverse proxy configuration
**Use:** Copy to `/etc/nginx/sites-available/dipanddash`

### 8. **supervisord_config.conf**
**Purpose:** Supervisor process manager configuration
**Use:** Copy to `/etc/supervisor/conf.d/dipanddash.conf`

---

## ⚡ QUICK START (TL;DR)

### Step 1: Connect to EC2
```powershell
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182
```

### Step 2: Setup (on EC2)
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3.10 python3.10-venv python3-pip build-essential libpq-dev postgresql-client git nginx supervisor
sudo mkdir -p /var/www/dipanddash
sudo chown -R ubuntu:ubuntu /var/www/dipanddash
```

### Step 3: Upload Project (from Windows)
```powershell
cd C:\DipandDashbackend
scp -i "food\Dipanddash.pem" -r food ubuntu@13.235.27.182:/var/www/dipanddash/
```

### Step 4: Deploy (on EC2)
```bash
cd /var/www/dipanddash/food
python3.10 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
mkdir -p /var/www/dipanddash/logs

# Create .env file with your config
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=change-this-to-something-random
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost
DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432
CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000
EOF

python manage.py migrate
python manage.py collectstatic --noinput
```

### Step 5: Setup Supervisor (on EC2)
```bash
sudo tee /etc/supervisor/conf.d/dipanddash.conf > /dev/null << 'EOF'
[program:dipanddash]
directory=/var/www/dipanddash/food
command=/var/www/dipanddash/food/venv/bin/gunicorn -w 4 -b 127.0.0.1:8000 food.wsgi:application
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/www/dipanddash/logs/gunicorn.log
EOF

sudo systemctl start supervisor
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start dipanddash
```

### Step 6: Setup Nginx (on EC2)
```bash
sudo tee /etc/nginx/sites-available/dipanddash > /dev/null << 'EOF'
upstream dipanddash_backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name 13.235.27.182 ec2-13-235-27-182.ap-south-1.compute.amazonaws.com;
    client_max_body_size 20M;

    location /static/ {
        alias /var/www/dipanddash/food/staticfiles/;
    }

    location /media/ {
        alias /var/www/dipanddash/food/media/;
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

sudo ln -s /etc/nginx/sites-available/dipanddash /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t
sudo systemctl start nginx && sudo systemctl enable nginx
```

### Step 7: Update Security Group in AWS Console
Add inbound rules:
- SSH (22): Your IP
- HTTP (80): 0.0.0.0/0
- HTTPS (443): 0.0.0.0/0

### Step 8: Access Your API
✅ **Your API will be available at:** `http://13.235.27.182`

---

## 🔧 Updated Django Settings

Your `settings.py` has been updated to support environment variables:

```python
from decouple import config

SECRET_KEY = config('SECRET_KEY', default='...')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*').split(',')

# Database config loaded from .env
DATABASES = {
    'default': {
        'ENGINE': config('DB_ENGINE', ...),
        'NAME': config('DB_NAME', ...),
        'USER': config('DB_USER', ...),
        'PASSWORD': config('DB_PASSWORD', ...),
        'HOST': config('DB_HOST', ...),
        'PORT': config('DB_PORT', ...),
    }
}
```

---

## 🔐 Important Notes

1. **Never commit passwords** - Use `.env` file (add to `.gitignore`)
2. **Change SECRET_KEY** - Generate new one for production
3. **Enable HTTPS** - Use Certbot for SSL certificate (Let's Encrypt)
4. **Backup database** - Set up automated backups for Neon
5. **Monitor logs** - Check logs regularly for errors

---

## 📝 .env Example (Create on EC2)

```env
DEBUG=False
SECRET_KEY=your-super-secret-key-here
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost,yourdomain.com

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432

# CORS
CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000,http://yourdomain.com
CSRF_TRUSTED_ORIGINS=http://13.235.27.182,http://yourdomain.com
CSRF_COOKIE_SECURE=False

# Security
SESSION_COOKIE_SECURE=False
```

---

## 🛠️ Useful Commands

### Connect to EC2
```bash
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182
```

### View Application Logs
```bash
sudo supervisorctl tail dipanddash -n 100
```

### Restart Application
```bash
sudo supervisorctl restart dipanddash
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Check Application Status
```bash
sudo supervisorctl status
```

### View Nginx Error Logs
```bash
sudo tail -f /var/log/nginx/error.log
```

### Update Application (after code changes)
```bash
cd /var/www/dipanddash/food
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo supervisorctl restart dipanddash
```

---

## ✅ Deployment Checklist

- [ ] SSH into EC2 successfully
- [ ] Installed Python, pip, git, nginx, supervisor
- [ ] Uploaded project to `/var/www/dipanddash/food`
- [ ] Created virtual environment
- [ ] Installed Python dependencies
- [ ] Created `.env` file with correct credentials
- [ ] Ran `python manage.py migrate`
- [ ] Ran `python manage.py collectstatic`
- [ ] Setup Supervisor for process management
- [ ] Setup Nginx as reverse proxy
- [ ] Updated Security Group to allow HTTP (80)
- [ ] Tested API at `http://13.235.27.182`
- [ ] Setup SSL/HTTPS (optional)

---

## 🎉 Next Steps

1. **Run DEPLOYMENT_CHECKLIST.md commands** - Follow step-by-step
2. **Test your API** - Visit `http://13.235.27.182` in browser
3. **Setup domain** - Point your domain to EC2 IP
4. **Setup SSL** - Use Certbot for HTTPS
5. **Monitor** - Set up CloudWatch alerts (optional)
6. **Backup** - Configure automated database backups

---

**Need help?** Check **DEPLOYMENT_GUIDE.md** for detailed explanations!

Happy deploying! 🚀
