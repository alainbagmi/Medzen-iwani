# Integration Configuration Summary

**Date:** Fri Dec  5 17:41:09 WAT 2025
**AWS EHRbase Endpoint:** http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase/rest

## Production Configuration

### EHRbase Details
- **URL:** http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase/rest
- **Username:** ehrbase-user
- **Password:** [Stored in AWS Secrets Manager: medzen-ehrbase/ehrbase_basic_auth]

### AWS Resources
- **ALB DNS:** medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com
- **ECS Cluster:** medzen-ehrbase-cluster
- **ECS Service:** medzen-ehrbase-service
- **Region:** eu-west-1

## Firebase Cloud Functions

**Configuration:**
```
ehrbase.url = "http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase/rest"
ehrbase.username = "ehrbase-user"
ehrbase.password = "[set via firebase functions:config:set]"
```

**Functions affected:**
- onUserCreated - Creates EHR in EHRbase when user signs up
- onUserDeleted - Cleanup operations

**Deployment command:**
```bash
cd firebase/functions
firebase deploy --only functions
```

## Supabase Edge Functions

**Secrets configured:**
- EHRBASE_URL
- EHRBASE_USERNAME
- EHRBASE_PASSWORD

**Functions affected:**
- sync-to-ehrbase - Processes ehrbase_sync_queue to sync data to EHRbase

**Deployment command:**
```bash
npx supabase functions deploy sync-to-ehrbase
```

## Verification Steps

1. **Test EHRbase API:**
   ```bash
   curl -u "ehrbase-user:${EHRBASE_PASSWORD}" \
     http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase/rest/status
   ```

2. **Test Firebase Function:**
   - Create a test user in Firebase Auth
   - Check Cloud Function logs: `firebase functions:log --only onUserCreated`
   - Verify EHR created in Supabase: `SELECT * FROM electronic_health_records ORDER BY created_at DESC LIMIT 1`

3. **Test Supabase Sync:**
   - Insert test data: `INSERT INTO vital_signs (...) VALUES (...)`
   - Check sync queue: `SELECT * FROM ehrbase_sync_queue WHERE sync_status = 'pending'`
   - Check function logs: `npx supabase functions logs sync-to-ehrbase`

4. **Test End-to-End:**
   - Run: `./06-validate-deployment.sh`

## Rollback Instructions

If issues occur, rollback to dev environment:

1. **Firebase:**
   ```bash
   firebase functions:config:set \
     ehrbase.url="" \
     ehrbase.username="" \
     ehrbase.password=""
   firebase deploy --only functions
   ```

2. **Supabase:**
   ```bash
   npx supabase secrets set \
     EHRBASE_URL="" \
     EHRBASE_USERNAME="" \
     EHRBASE_PASSWORD=""
   npx supabase functions deploy sync-to-ehrbase
   ```

## Next Steps

1. Validate deployment: `./06-validate-deployment.sh`
2. Monitor logs for 24 hours
3. Test user creation flow
4. Test offline sync functionality
5. Configure DNS and SSL for production domain

