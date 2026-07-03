#!/bin/bash

# Django Backend Deployment Script
# Run this script on the EC2 instance to deploy the application

set -e

PROJECT_PATH="/var/www/dipanddash"
PYTHON_VERSION="python3.10"

echo "================================"
echo "Starting Application Deployment..."
echo "================================"

# Clone or pull the repository
echo "📂 Setting up application files..."
if [ -d "$PROJECT_PATH/food" ]; then
    echo "Repository exists, pulling latest changes..."
    cd $PROJECT_PATH
    git pull origin main
else
    echo "Cloning repository..."
    cd $PROJECT_PATH
    # If you have a git repo, use: git clone <repo-url> food
    # For now, we'll assume files are uploaded manually
fi

# Navigate to project directory
cd $PROJECT_PATH/food

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
$PYTHON_VERSION -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt 2>/dev/null || pip install \
    Django==4.2.0 \
    djangorestframework==3.14.0 \
    django-cors-headers==4.0.0 \
    djangorestframework-simplejwt==5.2.2 \
    psycopg2-binary==2.9.6 \
    gunicorn==20.1.0 \
    pillow==9.5.0

# Create .env file
echo "🔐 Creating environment configuration..."
cat > $PROJECT_PATH/food/.env << 'EOF_ENV'
# Django Settings
DEBUG=False
SECRET_KEY=your-secret-key-change-this
ALLOWED_HOSTS=13.235.27.182,ec2-13-235-27-182.ap-south-1.compute.amazonaws.com,localhost

# Database Configuration (Neon PostgreSQL)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=npg_5IOm9xLqBQMU
DB_HOST=ep-winter-sunset-ah66qvua-pooler.c-3.us-east-1.aws.neon.tech
DB_PORT=5432

# CORS Settings
CORS_ALLOWED_ORIGINS=http://13.235.27.182,http://localhost:3000,http://127.0.0.1:3000

# JWT Settings
JWT_LIFETIME_DAYS=6
EOF_ENV

# Collect static files
echo "📦 Collecting static files..."
python manage.py collectstatic --noinput

# Run migrations
echo "🗄️ Running database migrations..."
python manage.py migrate

# Create superuser (optional - comment out if not needed)
# echo "👤 Creating superuser..."
# python manage.py createsuperuser --noinput --username admin --email admin@example.com

echo "✅ Application deployment completed!"
echo "================================"
