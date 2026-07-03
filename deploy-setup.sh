#!/bin/bash

# Django Backend EC2 Deployment Setup Script
# This script sets up the EC2 instance with all necessary dependencies

set -e

echo "================================"
echo "Starting EC2 Setup..."
echo "================================"

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Python and pip
echo "🐍 Installing Python 3.10..."
sudo apt-get install -y python3.10 python3.10-venv python3.10-dev python3-pip

# Install system dependencies
echo "📚 Installing system dependencies..."
sudo apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    nginx \
    git \
    curl \
    wget \
    supervisor

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/dipanddash
sudo chown -R ubuntu:ubuntu /var/www/dipanddash

echo "✅ System setup completed!"
echo "================================"
