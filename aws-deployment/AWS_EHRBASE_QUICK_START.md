# AWS EHRbase Quick Start Guide
**Fast Track Deployment - 30 Minutes**

## Prerequisites Check
```bash
# Verify tools (5 minutes)
aws --version          # ✓ AWS CLI v2.x
aws sts get-caller-identity  # ✓ AWS credentials configured
```

## 1. Deploy Infrastructure (15-20 minutes)

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment

# Deploy stack
aws cloudformation create-stack \
  --stack-name medzen-ehrbase-prod \
  --template-body file://cloudformation/ehrbase-infrastructure.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=medzen-ehrbase \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=DatabaseUsername,ParameterValue=ehrbase_admin \
    ParameterKey=DatabasePassword,ParameterValue=YOUR_STRONG_PASSWORD_HERE \
    ParameterKey=EHRbaseUsername,ParameterValue=ehrbase_user \
    ParameterKey=EHRbasePassword,ParameterValue=YOUR_EHRBASE_PASSWORD_HERE \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Wait for completion (15-20 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name medzen-ehrbase-prod \
  --region us-east-1
```

## 2. Get Endpoints (1 minute)

```bash
# Get ALB DNS
aws cloudformation describe-stacks \
  --stack-name medzen-ehrbase-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text

# Save this URL - you'll need it for Step 3
```

## 3. Test EHRbase (2 minutes)

```bash
# Replace with your ALB DNS from Step 2
ALB_DNS="medzen-ehrbase-alb-XXXXX.us-east-1.elb.amazonaws.com"

# Test status endpoint
curl -u ehrbase_user:YOUR_EHRBASE_PASSWORD \
  http://$ALB_DNS/ehrbase/rest/status

# Expected: {"status": "UP", ...}
```

## 4. Update Supabase (3 minutes)

```bash
# Set new EHRbase endpoint
npx supabase secrets set \
  EHRBASE_URL="http://$ALB_DNS/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase_user" \
  EHRBASE_PASSWORD="YOUR_EHRBASE_PASSWORD"

# Redeploy edge function
npx supabase functions deploy sync-to-ehrbase
```

## 5. Test Application (5 minutes)

1. Open your Flutter app
2. Navigate to Connection Test Page: `/connectionTest`
3. Run "Signup Flow" test
4. Verify new EHR created in AWS EHRbase

## Done! 🎉

**Next Steps:**
- [ ] Configure custom domain with SSL (optional)
- [ ] Migrate existing EHR data (if any)
- [ ] Set up CloudWatch alarms
- [ ] Enable Multi-AZ for production (optional)

**Resources:**
- Full deployment guide: `AWS_EHRBASE_DEPLOYMENT_GUIDE.md`
- Troubleshooting: See guide Section 9
- Monitoring: AWS Console → CloudWatch → Dashboards

**Estimated Monthly Cost:** $260
- ECS Fargate: ~$120
- RDS db.t3.medium: ~$70
- ALB: ~$25
- NAT Gateway: ~$35
- Data transfer: ~$10

**Questions?**
- Check deployment guide for detailed instructions
- Review CloudWatch logs: `/ecs/medzen-ehrbase`
- Test with: `curl -u user:pass http://ALB/ehrbase/rest/status`
