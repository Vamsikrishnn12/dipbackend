# 🔧 Fix SSH Connection - Step-by-Step Visual Guide

## THE PROBLEM
```
ssh: connect to host 13.235.27.182 port 22: Connection timed out
```

**Cause:** AWS Security Group doesn't allow SSH (port 22) connections

---

## THE FIX (3 MINUTES)

### STEP 1: Go to AWS EC2 Console
→ Open: https://ap-south-1.console.aws.amazon.com/ec2/instances/

You should see your instance:
```
Name: Dipanddash
Status: running ✅
Public IPv4: 13.235.27.182
```

**⚠️ Important:** Instance must say "running" - if stopped, click "Start instance"

---

### STEP 2: Click on Instance ID
Click the instance ID link (e.g., i-02d964d32e05489e4)

You'll see the instance details page:
```
Instance ID:  i-02d964d32e05489e4
Instance State: running
Public IPv4 DNS: ec2-13-235-27-182.ap-south-1.compute.amazonaws.com
Public IPv4 address: 13.235.27.182
```

---

### STEP 3: Go to Security Tab
Scroll down and click the **Security** tab

You should see:
```
← Back    Instance Details    Status Checks    Monitoring    Security
                                                                    ↑ CLICK
```

Under Security, you'll see:
```
Inbound rules (from: launch-wizard-1)
```

Click the security group link (in blue) - looks like: `sg-0xxx...` or `launch-wizard-1`

---

### STEP 4: Edit Inbound Rules
On the Security Group page, click **Edit inbound rules** button

You'll see existing rules. Now click **Add rule**

---

### STEP 5: Add SSH Rule

Fill in the new rule:
```
Type:           SSH
Protocol:       TCP (auto-filled)
Port range:     22
Source:         Your Computer's IP/32
```

**How to find YOUR IP:**
- Open: https://whatismyipaddress.com/
- Copy the IPv4 address (e.g., 203.0.113.42)
- Paste it in Source like: 203.0.113.42/32

**Or use (less secure):**
- Source: 0.0.0.0/0 (allows anyone)

---

### STEP 6: Save and Wait
1. Click **Save rules** button
2. Wait 30 seconds ⏱️
3. Rules are now active!

---

### STEP 7: Try SSH Again

Open PowerShell and run:
```powershell
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

**If successful, you should see:**
```
ubuntu@ip-172-31-xx-xx:~$ 
```

**🎉 You're connected!**

---

## COMPLETE SSH CHECKLIST

- [ ] Instance Status = "running"
- [ ] Instance has Public IP = 13.235.27.182
- [ ] Security Group has inbound SSH rule
- [ ] SSH rule has Port 22
- [ ] SSH rule Source includes YOUR IP or 0.0.0.0/0
- [ ] Waited 30 seconds for rule to apply
- [ ] Tried SSH command again
- [ ] Connection successful ✅

---

## IF STILL NOT WORKING

### Check 1: Instance AWS Status
```powershell
# In AWS Console:
# - Instance State should be "running" (green circle)
# - Not "stopped", "stopping", or "pending"
# - If stopped: Click "Instance State" → "Start instance"
```

### Check 2: Public IP Assignment
```powershell
# In AWS Console:
# - Go to EC2 → Instances
# - Your instance should show Public IPv4: 13.235.27.182
# - If showing "-", allocate Elastic IP:
#   - Right-click instance → Connect
#   - Or: EC2 → Elastic IPs → Allocate → Associate
```

### Check 3: Verify Your IP
```powershell
# Find your current public IP
[System.Net.Dns]::GetHostAddresses("myip.whatismyip.com") | Select-Object IPAddressToString

# Or visit: https://whatismyipaddress.com/
```

### Check 4: Test Connection
```powershell
# Test if port 22 is reachable
Test-NetConnection -ComputerName 13.235.27.182 -Port 22

# Should return: TcpTestSucceeded : True
```

---

## SECURITY GROUP FINAL CHECK

Go to **EC2 → Security Groups** and look for your instance's security group

You should see **Inbound rules** like:
```
Type         |  Protocol  |  Port   |  Source
─────────────┼────────────┼─────────┼──────────────────
SSH          |  TCP       |  22     |  203.0.113.42/32
HTTP         |  TCP       |  80     |  0.0.0.0/0
HTTPS        |  TCP       |  443    |  0.0.0.0/0
```

**Most important:** SSH rule with port 22 must exist!

---

## ONCE YOU'RE IN (After SSH Success)

First time in the instance:
```bash
ubuntu@ip-172-31-xx-xx:~$ echo "✅ Success!"
ubuntu@ip-172-31-xx-xx:~$ whoami
ubuntu
ubuntu@ip-172-31-xx-xx:~$ pwd
/home/ubuntu
```

Then follow the deployment steps:
1. Read: **DEPLOYMENT_CHECKLIST.md**
2. Run step-by-step commands

---

**Quick Copy-Paste Command:**
```powershell
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

---

**Still stuck?** Make sure:
1. ✅ AWS Security Group allows port 22
2. ✅ Instance is running
3. ✅ PEM file path is correct
4. ✅ You waited 30 seconds after changing rules

Try again with the fixed security group! 🚀
