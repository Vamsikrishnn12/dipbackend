# 🔴 CRITICAL: Instance Not Reachable - Complete AWS Troubleshooting

## The Problem
```
Ping to 13.235.27.182: ❌ TIMEOUT
SSH to 13.235.27.182: ❌ CONNECTION TIMEOUT
```

**This means the instance is BLOCKED at the network level (before SSH even runs)**

---

## SOLUTION: Step-by-Step AWS Console Check

### STEP 1: Verify Instance is Actually RUNNING

1. Open: https://ap-south-1.console.aws.amazon.com/ec2/instances/
2. Look at your "Dipanddash" instance
3. Check column "Instance state"
   - ✅ Must show: **running** (green dot)
   - ❌ If shows: "stopped", "stopping", "pending" - **START IT**

**How to Start:**
- Right-click instance → Instance State → Start instance
- Wait 60 seconds for startup

---

### STEP 2: Verify Instance Has PUBLIC IP

1. Click on the instance name
2. Scroll to "Details" section
3. Look for "Public IPv4 address"
   - ✅ Should show: **13.235.27.182**
   - ❌ If shows: **-** (dash), then NO PUBLIC IP assigned
   - ❌ If shows: different IP, update accordingly

**If PUBLIC IP is "-" (not assigned):**

**Option A: Allocate Elastic IP**
1. Go to: EC2 → Elastic IPs
2. Click "Allocate Elastic IP address"
3. Click "Allocate"
4. Right-click new IP → Associate
5. Select your instance
6. Click "Associate"

**Option B: Check VPC Settings**
1. Go to: EC2 Dashboard
2. Left sidebar → Network Interfaces
3. Find your instance's network interface
4. Right-click → Assign new address
5. Use Auto-assign public IP

---

### STEP 3: Check VPC Has Internet Gateway

1. Go to: EC2 Dashboard → VPC
2. Or: https://ap-south-1.console.aws.amazon.com/vpc/
3. Left sidebar → Internet Gateways
4. Should show: **igw-xxxxx** with Status = Attached
5. If none exist:
   - Click "Create internet gateway"
   - Create it
   - Attach to your VPC

---

### STEP 4: Check Route Tables

1. VPC Dashboard → Route Tables
2. Find route table for your instance's subnet
3. Check routes:
   - ✅ Should have: `0.0.0.0/0` → `igw-xxxxx`
4. If missing:
   - Click route table
   - Edit routes
   - Add route: `0.0.0.0/0` → Internet Gateway

---

### STEP 5: Check Network ACLs (Firewall)

1. VPC Dashboard → Network ACLs
2. Find your subnet's NACL
3. Check **Inbound Rules**:
   - Should allow: ALL traffic or TCP port 22
4. Check **Outbound Rules**:
   - Should allow: ALL traffic

If restrictive:
- Edit rules
- Allow all traffic (0.0.0.0/0)

---

### STEP 6: Check Security Group (Again More Carefully)

1. EC2 Dashboard → Security Groups
2. Find: **launch-wizard-1**
3. Click it
4. Check **Inbound rules** section:

**You should see:**
```
Type     | Protocol | Port | Source
─────────┼──────────┼──────┼──────────────────
SSH      | TCP      | 22   | 0.0.0.0/0  (or YOUR_IP/32)
RDP      | TCP      | 3389 | ...
...
```

**If SSH is missing:**
- Click "Edit inbound rules"
- "Add rule"
- Type: SSH, Protocol: TCP, Port: 22, Source: 0.0.0.0/0
- Save

---

### STEP 7: Restart Instance (Nuclear Option)

If still not working:

1. Go to: EC2 → Instances
2. Right-click Dipanddash
3. Instance State → Reboot instance
4. Wait 60 seconds
5. Try SSH again

---

## QUICK CHECKLIST

- [ ] Instance State = **running** ✅
- [ ] Public IPv4 = **13.235.27.182** (not "-") ✅
- [ ] Elastic IP assigned (if needed) ✅
- [ ] VPC has Internet Gateway attached ✅
- [ ] Route table has 0.0.0.0/0 -> IGW route ✅
- [ ] Network ACLs allow SSH (port 22) ✅
- [ ] Security Group has SSH inbound rule ✅
- [ ] Security Group SSH source = 0.0.0.0/0 or YOUR_IP ✅
- [ ] Waited 30 seconds after each change ✅
- [ ] Tested SSH again ✅

---

## TEST CONNECTIVITY

After completing the checklist:

### Test 1: Ping (Should work)
```powershell
ping 13.235.27.182
```

### Test 2: SSH (Should work)
```powershell
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

### If Both Fail: Advanced Debugging

```powershell
# Test with verbose SSH output
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182 -vvv

# Check network interface on AWS
# EC2 -> Network Interfaces -> Find your interface -> Details
```

---

## LAST RESORT: Terminate & Create New Instance

If nothing works:

1. EC2 → Instances
2. Right-click Dipanddash → Terminate instance
3. Create NEW instance:
   - AMI: Ubuntu 22.04 LTS
   - Instance type: t3.small
   - VPC: default
   - Subnet: default (public)
   - Auto-assign Public IP: **ENABLE** ← IMPORTANT
   - Security Group: Create new
     - Allow SSH (22): 0.0.0.0/0
     - Allow HTTP (80): 0.0.0.0/0
   - Key pair: Select Dipanddash.pem

---

## SUMMARY

The fact that **ping fails** means it's NOT a Security Group issue anymore - it's a **VPC/Network Interface issue**.

**Most likely:**
1. ❌ Instance in private subnet without IGW
2. ❌ No public IP assigned
3. ❌ Network ACL blocking traffic
4. ❌ Network interface detached

**Next action:** Follow the VPC/IGW/Route checks above!

---

**Still stuck?** AWS Support is your best bet - they can check actual network logs.
