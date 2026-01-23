# MedZen AWS Infrastructure Verification - Phase 2 Execution Guide

**Date:** 2026-01-23
**Status:** Ready for Execution
**Estimated Duration:** 1 hour (with AWS credentials)
**Risk Level:** LOW - Verification only, no breaking changes

---

## Overview

Phase 2 verifies and enables critical AWS security services required for HIPAA/GDPR compliance:

1. **S3 Encryption** - Enable KMS encryption on 3 buckets (PHI storage)
2. **GuardDuty** - Threat detection and anomaly monitoring
3. **CloudTrail** - API audit logging and compliance tracking

---

## Prerequisites

Before executing Phase 2, ensure you have:

- ✅ AWS CLI installed and configured
- ✅ AWS credentials with appropriate permissions:
  - `kms:*` - KMS key creation and management
  - `s3:*` - S3 bucket encryption configuration
  - `guardduty:*` - GuardDuty detector management
  - `cloudtrail:*` - CloudTrail trail management
- ✅ Appropriate IAM role attached (typically `AdministratorAccess` or custom policy)

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Expected output:
# {
#   "UserId": "...",
#   "Account": "558069890522",
#   "Arn": "arn:aws:iam::558069890522:..."
# }
```

---

## Task 2.1: Execute S3 Encryption Script

**Objective:** Enable KMS encryption on 3 S3 buckets containing PHI

**Buckets to Encrypt:**
1. `medzen-meeting-recordings-558069890522` - Recording files
2. `medzen-meeting-transcripts-558069890522` - Transcription audio
3. `medzen-medical-data-558069890522` - Clinical records

### Step 1: Execute Script

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
chmod +x aws-deployment/scripts/enable-s3-encryption.sh
./aws-deployment/scripts/enable-s3-encryption.sh
```

### Expected Output

```
🔒 MedZen HIPAA S3 Encryption Setup
====================================

📋 Region: eu-central-1
📋 Account: 558069890522

🔑 Creating KMS key for S3 encryption...
✅ KMS Key created: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
✅ KMS Key alias created: alias/medzen-s3-phi

🔐 Enabling encryption on S3 buckets...

📦 Processing bucket: medzen-meeting-recordings-558069890522
  ✅ Encryption enabled
📦 Processing bucket: medzen-meeting-transcripts-558069890522
  ✅ Encryption enabled
📦 Processing bucket: medzen-medical-data-558069890522
  ✅ Encryption enabled

...

====================================
✅ S3 Encryption Setup Complete
====================================

KMS Key ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Encrypted Buckets: 3

📝 Store this KMS Key ID in your environment:
export AWS_S3_KMS_KEY_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
```

### Step 2: Capture KMS Key ID

The script will output a KMS Key ID. **Store this securely:**

```bash
# Add to .env file
echo "AWS_S3_KMS_KEY_ID='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'" >> .env

# Or add to AWS Systems Manager Parameter Store (recommended)
aws ssm put-parameter \
  --name /medzen/kms/s3-key-id \
  --value 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' \
  --type SecureString \
  --region eu-central-1
```

### Step 3: Verify Encryption

```bash
# Verify encryption on each bucket
aws s3api get-bucket-encryption \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1

# Expected output:
# {
#   "ServerSideEncryptionConfiguration": {
#     "Rules": [{
#       "ApplyServerSideEncryptionByDefault": {
#         "SSEAlgorithm": "aws:kms",
#         "KMSMasterKeyID": "arn:aws:kms:eu-central-1:558069890522:key/..."
#       },
#       "BucketKeyEnabled": true
#     }]
#   }
# }
```

**Success Criteria:**
- ✅ `SSEAlgorithm` is `aws:kms`
- ✅ `KMSMasterKeyID` is present and valid
- ✅ `BucketKeyEnabled` is `true`

---

## Task 2.2: Verify GuardDuty Status

**Objective:** Ensure GuardDuty threat detection is enabled

### Step 1: Execute Verification Script

```bash
chmod +x aws-deployment/scripts/verify-guardduty.sh
./aws-deployment/scripts/verify-guardduty.sh
```

### Expected Output (if already enabled)

```
🔍 MedZen GuardDuty Verification
==================================

📋 Checking GuardDuty Status...
Region: eu-central-1
Account: 558069890522

✅ GuardDuty detector found: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  - Detector ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    Status: ENABLED
    ✅ GuardDuty is ENABLED

==================================
✅ GuardDuty Verification Complete
==================================
```

### If GuardDuty Is Not Enabled

The script will automatically create and enable a detector.

### Step 2: Verify Findings (Manual)

```bash
# List recent GuardDuty findings
aws guardduty list-findings \
  --detector-id [DETECTOR_ID] \
  --region eu-central-1 \
  --max-results 10

# Get finding details
aws guardduty get-findings \
  --detector-id [DETECTOR_ID] \
  --finding-ids [FINDING_ID] \
  --region eu-central-1
```

**Success Criteria:**
- ✅ GuardDuty detector is ENABLED
- ✅ Finding publishing frequency is FIFTEEN_MINUTES
- ✅ No critical findings (or findings are reviewed and dismissed)

---

## Task 2.3: Verify CloudTrail Status

**Objective:** Ensure CloudTrail audit logging is enabled

### Step 1: Execute Verification Script

```bash
chmod +x aws-deployment/scripts/verify-cloudtrail.sh
./aws-deployment/scripts/verify-cloudtrail.sh
```

### Expected Output

```
🔍 MedZen CloudTrail Verification
==================================

📋 Checking CloudTrail Status...
Region: eu-central-1
Account: 558069890522
Trail: medzen-audit-trail

✅ CloudTrail trail found: medzen-audit-trail

📋 Checking trail configuration...
✅ S3 Bucket configured
✅ Multi-region trail enabled
✅ Log file validation enabled

📋 Checking logging status...
✅ CloudTrail logging is ACTIVE

📋 Recent CloudTrail Events (last 10):
...

==================================
✅ CloudTrail Verification Complete
==================================
```

### If CloudTrail Is Not Enabled

The script will automatically create and enable it.

### Step 2: Verify S3 Bucket for Logs

```bash
# Check if CloudTrail logs bucket exists
aws s3 ls medzen-cloudtrail-logs --region eu-central-1

# Expected: List of log files

# Check S3 bucket encryption
aws s3api get-bucket-encryption \
  --bucket medzen-cloudtrail-logs \
  --region eu-central-1
```

**Success Criteria:**
- ✅ Trail name is `medzen-audit-trail`
- ✅ Multi-region trail is ENABLED
- ✅ Log file validation is ENABLED
- ✅ Logging status is ACTIVE (True)
- ✅ S3 bucket exists and contains logs

---

## Task 2.4: Verify Cross-Service Integration

After all three services are verified, run integration checks:

### Check 1: KMS Key Policies Allow Services

```bash
# Get KMS key policy
aws kms get-key-policy \
  --key-id alias/medzen-s3-phi \
  --policy-name default \
  --region eu-central-1

# Verify output includes:
# - S3 service principal
# - Lambda service principal
# - CloudTrail permissions
```

### Check 2: S3 Bucket Policies Block Unencrypted Uploads

```bash
# Get bucket policy
aws s3api get-bucket-policy \
  --bucket medzen-meeting-recordings-558069890522 \
  --region eu-central-1

# Verify output includes:
# - DenyUnencryptedObjectUploads statement
# - s3:x-amz-server-side-encryption condition
```

### Check 3: GuardDuty Integration

```bash
# Verify GuardDuty findings are publishing
aws guardduty list-findings \
  --detector-id [DETECTOR_ID] \
  --region eu-central-1

# Should return findings (even if empty, endpoint works)
```

---

## Phase 2 Checklist

After completing all tasks:

```
□ Step 1: S3 Encryption Enabled
  □ KMS key created (alias: alias/medzen-s3-phi)
  □ All 3 buckets encrypted with KMS
  □ Unencrypted uploads blocked
  □ KMS Key ID stored in .env or Parameter Store

□ Step 2: GuardDuty Enabled
  □ Detector created and ENABLED
  □ Finding publishing frequency: FIFTEEN_MINUTES
  □ No unreviewed critical findings
  □ Detection rules configured

□ Step 3: CloudTrail Enabled
  □ Trail created (medzen-audit-trail)
  □ Multi-region trail: ENABLED
  □ Log file validation: ENABLED
  □ Logging status: ACTIVE
  □ S3 bucket receiving logs

□ Step 4: Integration Verified
  □ KMS policies allow S3, Lambda, CloudTrail
  □ S3 bucket policies enforce encryption
  □ GuardDuty findings accessible
  □ CloudTrail logs in S3

□ Step 5: Documentation
  □ KMS Key ID documented
  □ GuardDuty Detector ID documented
  □ CloudTrail trail name documented
  □ All IDs stored securely
```

---

## Troubleshooting

### Issue: "Failed to create KMS key"

**Cause:** Insufficient IAM permissions

**Solution:**
```bash
# Ensure your IAM user/role has kms:CreateKey
# Check AWS IAM console: Users/Roles → Permissions

# If needed, attach policy:
aws iam attach-user-policy \
  --user-name [YOUR_USERNAME] \
  --policy-arn arn:aws:iam::aws:policy/KMSFullAccess
```

### Issue: "Bucket does not exist"

**Cause:** S3 bucket hasn't been created yet

**Solution:**
```bash
# Create missing buckets
aws s3 mb s3://medzen-meeting-recordings-558069890522 \
  --region eu-central-1

aws s3 mb s3://medzen-meeting-transcripts-558069890522 \
  --region eu-central-1

aws s3 mb s3://medzen-medical-data-558069890522 \
  --region eu-central-1

# Then re-run encryption script
```

### Issue: "GuardDuty detector not found"

**Cause:** GuardDuty not initialized in region

**Solution:** Script will auto-create detector, or manually:

```bash
aws guardduty create-detector \
  --region eu-central-1 \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES
```

### Issue: "CloudTrail S3 bucket does not exist"

**Cause:** S3 bucket for CloudTrail logs not created

**Solution:**
```bash
# Create CloudTrail S3 bucket
aws s3 mb s3://medzen-cloudtrail-logs-558069890522 \
  --region eu-central-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket medzen-cloudtrail-logs-558069890522 \
  --versioning-configuration Status=Enabled

# Re-run CloudTrail script
```

---

## Post-Phase 2: Next Steps

**Phase 1 (Concurrent):** Edge function security hardening continues in background
**Phase 3:** Documentation already complete ✅
**Phase 4:** Security testing (after Phase 1 complete)

---

## Related Documentation

- [MEDZEN_SECURE_DEPLOYMENT_GUIDE.md](./MEDZEN_SECURE_DEPLOYMENT_GUIDE.md) - Comprehensive deployment guide
- [SECURITY-TESTING-PROCEDURES.md](./security/SECURITY-TESTING-PROCEDURES.md) - Security testing framework
- [INCIDENT-RESPONSE-PLAYBOOK.md](./security/INCIDENT-RESPONSE-PLAYBOOK.md) - Incident response procedures
- [AWS BAA Execution Guide](./compliance/AWS-BAA-EXECUTION-GUIDE.md) - HIPAA BAA requirements

---

**Document Version:** 1.0
**Created:** 2026-01-23
**Last Updated:** 2026-01-23
**Status:** Ready for Execution
**Approval:** Required before execution (AWS account changes)
