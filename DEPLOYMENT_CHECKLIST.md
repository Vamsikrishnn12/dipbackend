# EC2 Deployment Quick Checklist & Commands

## 🚀 QUICK START (Step-by-Step)

### 1. **Connect to EC2** (Run from your Windows terminal)

```powershell
# From C:\DipandDashbackend folder
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182
```

### 2. **First Time Setup** (Run on EC2)

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Python and tools
sudo apt-get install -y python3.10 python3.10-venv python3-pip \
    build-essential libpq-dev postgresql-client git nginx supervisor

# Create app directory
sudo mkdir -p /var/www/dipanddash
sudo chown -R ubuntu:ubuntu /var/www/dipanddash
cd /var/www/dipanddash
```

### 3. **Upload Your Project** (From Windows)

**Option A: Using SCP (Recommended)**
```powershell
cd C:\DipandDashbackend
scp -i "food\Dipanddash.pem" -r food ubuntu@13.235.27.182:/var/www/dipanddash/
```

**Option B: Clone from Git** (If you have a repo)
```bash
cd /var/www/dipanddash
git clone <your-repo-url> food
cd food
```

### 4. **Deploy Application** (On EC2)

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

# Create .env file
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=your-secret-key-here-make-it-random-and-long-change-this
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost

DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432

CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000
CSRF_TRUSTED_ORIGINS=http://13.235.27.182,http://localhost:3000
EOF

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Create superuser (optional)
# python manage.py createsuperuser
```

### 5. **Setup Supervisor** (Process Manager) - On EC2

```bash
# Create supervisor config
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

# Apply changes
sudo systemctl start supervisor
sudo systemctl enable supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start dipanddash

# Check status
sudo supervisorctl status
```

### 6. **Setup Nginx** (Web Server) - On EC2

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

# Enable config
sudo ln -s /etc/nginx/sites-available/dipanddash /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test and start
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 7. **Update Security Group** (AWS Console)

1. Go to EC2 → Security Groups
2. Find your instance's security group
3. Add **Inbound Rules**:
   - SSH: Port 22, Source: Your IP
   - HTTP: Port 80, Source: 0.0.0.0/0
   - HTTPS: Port 443, Source: 0.0.0.0/0 (optional, for later)

### 8. **Test Your Deployment** (On EC2)

```bash
# Test Gunicorn
curl http://127.0.0.1:8000

# Test Nginx
curl http://localhost

# View logs
tail -f /var/www/dipanddash/logs/gunicorn.log
sudo tail -f /var/log/nginx/error.log
```

### 9. **Access Your API**

✅ **Your API is now live at:** `http://13.235.27.182`

Test with:
```bash
curl http://13.235.27.182/api/your-endpoint/
```

---

## 📋 Common Commands for Management

```bash
# SSH into EC2
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182

# View application logs
sudo supervisorctl tail dipanddash -n 100

# Restart application
sudo supervisorctl restart dipanddash

# Stop application
sudo supervisorctl stop dipanddash

# Start application
sudo supervisorctl start dipanddash

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx status
sudo systemctl status nginx

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

---

## 🔄 Updating Your Application

After making changes and want to redeploy:

```bash
# SSH into EC2
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182

# Update code
cd /var/www/dipanddash/food
git pull origin main  # or manually upload new files

# Activate venv and install new deps
source venv/bin/activate
pip install -r requirements.txt

# Run migrations (if DB changed)
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Restart application
sudo supervisorctl restart dipanddash
```

---

## 🔒 Security Improvements

### Setup SSL/HTTPS (Optional but Recommended)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ec2-13-235-27-182.ap-south-1.compute.amazonaws.com
sudo systemctl restart nginx
```

### Change SECRET_KEY

Generate a new secret key:
```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Update in `.env` file and restart:
```bash
sudo supervisorctl restart dipanddash
```

---

## ❌ Troubleshooting

### Can't connect via SSH
```bash
# Re-check PEM file permissions (Windows PowerShell as Admin)
icacls.exe "Dipanddash.pem" /reset
icacls.exe "Dipanddash.pem" /grant:r "$($env:USERNAME):(F)"

# Try connecting again
ssh -i "food\Dipanddash.pem" ubuntu@13.235.27.182
```

### Gunicorn not starting
```bash
cd /var/www/dipanddash/food
source venv/bin/activate
python manage.py check  # Check for errors
sudo supervisorctl tail dipanddash -n 50  # Check logs
```

### Database connection error
```bash
# Test database connection
psql -h ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech \
  -U neondb_owner -d neondb -c "SELECT 1"
```

### Nginx showing 502 Bad Gateway
- Check if Gunicorn is running: `sudo supervisorctl status`
- Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Restart Nginx: `sudo systemctl restart nginx`

---

## 📊 Monitoring Commands

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
ps aux | grep gunicorn

# Check port 8000 is listening
sudo lsof -i :8000

# Check port 80 is listening
sudo lsof -i :80
```

---

## 📞 Support

For database issues: Check [Neon PostgreSQL docs](https://neon.tech/docs)
For Django issues: Check [Django docs](https://docs.djangoproject.com)
For Nginx issues: Check [Nginx docs](https://nginx.org/en/docs/)

Happy deploying! 🚀
