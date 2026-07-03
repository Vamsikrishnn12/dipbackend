# EC2 Instance Network Troubleshooting - AWS Console Steps

## ⚡ STEP 1: REBOOT THE INSTANCE (Do This First)

1. Open: https://ap-south-1.console.aws.amazon.com/ec2/instances/
2. Find instance: **Dipanddash**
3. Right-click on it
4. Select: **Instance State** → **Reboot instance**
5. Click **Reboot**
6. ⏳ Wait 2 minutes for reboot to complete
7. Try SSH again:
   ```powershell
   ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
   ```

---

## If Reboot Doesn't Work - Check These (In Order)

### CHECK 1: Instance Status

1. Go to: https://ap-south-1.console.aws.amazon.com/ec2/instances/
2. Look at your instance row

**Verify:**
- [ ] Instance State = **running** (green circle)
- [ ] Public IPv4 = **13.235.27.182** (not "-")
- [ ] Public IPv4 DNS = **ec2-13-235-27-182.ap-south-1.compute.amazonaws.com**

**If Public IPv4 shows "-" (no IP assigned):**

→ Go to: EC2 Dashboard → Network Interfaces
→ Find your instance's network interface
→ Click it
→ Actions → Manage IP addresses
→ Auto-assign IPv4 address: Enable
→ Save

---

### CHECK 2: Subnet & VPC Settings

1. Go to: https://ap-south-1.console.aws.amazon.com/vpc/
2. Click: **Subnets** (left sidebar)
3. Find subnet for your instance

**Look for Column: "Auto-assign IPv4"**
- [ ] Should be: **Yes** (not No)

If "No":
- Select subnet
- Edit subnet settings
- Enable: "Auto-assign IPv4 address"
- Save

---

### CHECK 3: Internet Gateway

1. VPC Dashboard → Internet Gateways (left sidebar)
2. Look for any Internet Gateway

**Must exist and be:**
- [ ] Status = **Attached**
- [ ] Attached to your VPC

**If none exist or not attached:**
1. Click: "Create internet gateway"
2. Name: dipanddash-igw
3. Create
4. Select it
5. Attach to VPC
6. Select your VPC
7. Attach

---

### CHECK 4: Route Tables

1. VPC Dashboard → Route Tables (left sidebar)
2. Find route table for your subnet

**Check Routes tab:**

Must have route:
```
Destination: 0.0.0.0/0
Target: igw-xxxxx (Internet Gateway)
```

**If missing:**
1. Click route table
2. Routes tab
3. Edit routes
4. Add route:
   - Destination: 0.0.0.0/0
   - Target: Internet Gateway → select your IGW
5. Save

---

### CHECK 5: Network ACLs

1. VPC Dashboard → Network ACLs
2. Find your subnet's NACL

**Check Inbound Rules:**

Should allow:
- [ ] Rule for TCP port 22 (SSH)
- [ ] Or allow ALL traffic

**If too restrictive:**
1. Select NACL
2. Inbound rules
3. Add rule:
   - Rule number: 100
   - Type: SSH (22)
   - Protocol: TCP
   - Port: 22
   - Source: 0.0.0.0/0
   - Allow/Deny: Allow

---

## After Making Changes

1. Wait 30-60 seconds ⏱️
2. **Reboot instance again** (if you made changes)
3. Wait 2 minutes
4. Try SSH:

```powershell
ssh -i "C:\DipandDashbackend\food\Dipanddash.pem" ubuntu@13.235.27.182
```

---

## Verification Checklist

After completing all checks, you should have:

- [x] Instance State: **running**
- [x] Public IPv4: **13.235.27.182**
- [x] Internet Gateway: **Attached to VPC**
- [x] Route Table: **0.0.0.0/0 → Internet Gateway**
- [x] Subnet: **Auto-assign IPv4: Yes**
- [x] Network ACLs: **Allow SSH/All**
- [x] Security Group: **Allow SSH port 22**

---

## Alternative: Create Fresh Instance

If you've tried everything and nothing works:

**Option: Terminate current and create new instance with correct settings**

1. EC2 → Instances
2. Right-click Dipanddash → **Terminate instance**
3. Create new instance:
   - AMI: **Ubuntu Server 22.04 LTS**
   - Instance type: **t3.small**
   - VPC: **Default**
   - Subnet: **Default (public)**
   - Auto-assign public IP: **ENABLE** ← CRITICAL
   - Security Group: **Create new**
     - Inbound: SSH (22) from 0.0.0.0/0
     - Inbound: HTTP (80) from 0.0.0.0/0
   - Key pair: **Dipanddash**

---

## Summary

**Most likely causes:**
1. ❌ Instance needs reboot
2. ❌ No Internet Gateway attached to VPC
3. ❌ Route table missing default route to IGW
4. ❌ Auto-assign public IP disabled
5. ❌ Network ACLs too restrictive

**Next action:** 
→ Reboot instance
→ If fails: Check Internet Gateway attachment
→ If fails: Check Route Table routes
→ If fails: Create new instance with correct settings
