# 🚨 SSH Connection Timeout FIX

## Problem
```
ssh: connect to host 13.235.27.182 port 22: Connection timed out
```

## Solution: Update AWS Security Group

### Step 1: Go to AWS EC2 Console
1. Open: https://ap-south-1.console.aws.amazon.com/ec2/
2. Click **Instances** in left sidebar
3. Click on your **Dipanddash** instance

### Step 2: Check Instance Status
✅ Instance must show **Running** status
✅ Public IP must show: **13.235.27.182**

### Step 3: Open Security Group Settings
1. In instance details, scroll to **Security** tab
2. Click on the **Security group** link (e.g., `launch-wizard-1`)
3. You'll see the security group page

### Step 4: Add SSH Inbound Rule
1. Click **Edit inbound rules** button
2. Click **Add rule** button
3. Fill in:
   - **Type:** SSH
   - **Protocol:** TCP
   - **Port Range:** 22
   - **Source:** 
     * Option A: Your computer's IP (find it at whatismyipaddress.com)
     * Option B: Anywhere (0.0.0.0/0) - NOT recommended for production
4. Click **Save rules**

### Step 5: Wait & Retry
- Wait 30 seconds for rules to apply
- Try SSH again:
```powershell
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

---

## Alternative: Check Instance Public IP

If you see "-" instead of an IP in AWS console:

1. Click on instance
2. Go to **Details** tab
3. Scroll down to **Network interfaces**
4. Click the network interface link
5. Go to **Elastic IPs**
6. Allocate new Elastic IP and associate with instance

---

## Quick SSH Command (Use This Path)

```powershell
# Full path version (always works)
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182

# Or from PowerShell as Admin
Get-ChildItem "C:\DipandDashbackend\food\Dipanddash.pem" | Get-Item
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

---

## If Still Not Working

Run this diagnostic:

```powershell
# Check PEM file exists
Test-Path "C:\DipandDashbackend\food\Dipanddash.pem"

# Try with verbose
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182 -vvv

# Check if port 22 is open to you
Test-NetConnection -ComputerName 13.235.27.182 -Port 22

# Check basic connectivity
ping 13.235.27.182
```

---

## AWS Security Group Checklist

✅ Instance is **Running**  
✅ Instance has **Public IP** (13.235.27.182)  
✅ Security Group has **SSH rule**  
✅ SSH rule **Port 22** is open  
✅ SSH rule **Source** includes your IP  
✅ Waited 30 seconds after editing rules  

If all ✅, then try SSH again!

---

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| PEM file not found | Use full path: `C:\DipandDashbackend\food\Dipanddash.pem` |
| Permission denied (publickey) | Fix PEM permissions: `icacls "Dipanddash.pem" /inheritance:r /grant:r "%username%:(F)"` |
| Connection timeout | Add SSH rule to Security Group port 22 |
| Connection refused | EC2 instance might not be running |
| Publickey authentication issues | Make sure PEM file is readable |

---

## Once Connected

First connection test:
```bash
echo "✅ SSH working!"
whoami                 # Should show: ubuntu
pwd                    # Should show: /home/ubuntu
```

Continue deployment:
- Follow **DEPLOYMENT_CHECKLIST.md**
- Or run: `bash /path/to/deploy-app.sh` (if uploaded)

---

**Need help?** Check AWS EC2 → Security Groups → Inbound Rules
