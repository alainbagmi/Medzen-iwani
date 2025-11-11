# Payments RLS Fix - Summary

**Date:** 2025-11-06
**Status:** ✅ **FIXED**
**Migration:** `20251106140000_fix_payments_rls_policies.sql`

---

## Problem

FlutterFlow was getting **400 Bad Request** errors when trying to insert payments:
- Requests were using the `anon` role (unauthenticated)
- Original RLS policy required `auth.uid() = payer_id`
- Since anon users have `auth.uid() = NULL`, the policy blocked all inserts

## Solution

Created new RLS policies that allow payment creation from both authenticated and anonymous users while maintaining security:

### 1. **Authenticated User Policy** (Production-Ready)
```sql
CREATE POLICY "Authenticated users can create payments"
ON public.payments
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = payer_id);
```
- ✅ Secure - requires authentication
- ✅ Validates user is the payer

### 2. **Anonymous User Policy** (Testing/Development)
```sql
CREATE POLICY "Allow payment creation for testing"
ON public.payments
FOR INSERT TO anon
WITH CHECK (
  payment_reference IS NOT NULL
  AND payment_for IS NOT NULL
  AND payment_method IS NOT NULL
  AND gross_amount IS NOT NULL
  AND net_amount IS NOT NULL
  AND gross_amount <= 1000000  -- Max 1M XAF safety limit
);
```
- ⚠️ **Warning:** This policy allows anonymous payment creation
- ✅ Validates all required fields are present
- ✅ Limits payment amount to 1M XAF for safety
- ⚠️ **Should be reviewed before production deployment**

### 3. **Secure Payment Creation Function**
```sql
CREATE FUNCTION create_payment_secure(...)
RETURNS UUID
SECURITY DEFINER;
```
- ✅ Bypasses RLS with SECURITY DEFINER
- ✅ Auto-generates payment reference
- ✅ Captures user_agent and IP address
- ✅ Can be called from FlutterFlow for safer payment creation

### 4. **Additional Improvements**
- ✅ Added UPDATE policies for payment status changes
- ✅ Added view policies for anonymous users (recent payments by IP)
- ✅ Maintained all admin and facility-specific policies
- ✅ Added helper function to disable testing policies for production

---

## Testing Results

✅ **Payment creation with anon key:** SUCCESS
```json
{
  "id": "b702acab-87b3-48e4-8a25-4cfe715740ab",
  "payment_reference": "TEST-20251106-095131-2A66EE",
  "payment_for": "consultation",
  "payment_method": "cash",
  "gross_amount": 5000.00,
  "net_amount": 5000.00,
  "payment_status": "initiated"
}
```

---

## Usage in FlutterFlow

### Option 1: Direct Insert (Anon Key - Testing)
```dart
// FlutterFlow Backend Call → Supabase Insert
await SupaFlow.client.from('payments').insert({
  'payment_reference': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
  'payment_for': 'consultation',
  'payment_method': 'orange_money',
  'gross_amount': 5000.00,
  'net_amount': 5000.00,
  'currency': 'XAF',
  'payment_status': 'initiated',
  // payer_id is optional for anon users
});
```

### Option 2: Authenticated Insert (Recommended)
```dart
// Ensure user is authenticated
if (currentUserUid != null) {
  await SupaFlow.client.from('payments').insert({
    'payment_reference': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
    'payer_id': currentUserUid,  // Required for authenticated
    'payment_for': 'consultation',
    'payment_method': 'orange_money',
    'gross_amount': 5000.00,
    'net_amount': 5000.00,
    'currency': 'XAF',
  });
}
```

### Option 3: Using Secure Function (Most Secure)
```dart
// FlutterFlow Backend Call → Supabase RPC
final paymentId = await SupaFlow.client.rpc(
  'create_payment_secure',
  params: {
    'p_payment_for': 'consultation',
    'p_payment_method': 'orange_money',
    'p_gross_amount': 5000.00,
    'p_net_amount': 5000.00,
    'p_payer_id': currentUserUid,  // Optional - auto-uses auth.uid()
    'p_related_data': {
      'consultation_id': consultationId,
      'provider_id': providerId,
    },
  },
);
```

---

## Valid Field Values

### payment_for (Required)
- `consultation`, `prescription`, `lab_test`, `imaging`, `procedure`
- `appointment_booking`, `insurance_premium`, `facility_fee`
- `blood_donation_incentive`, `subscription`, `late_fee`

### payment_method (Required)
- `orange_money`, `mtn_momo`, `visa`, `mastercard`
- `bank_transfer`, `cash`, `insurance`, `credit`, `voucher`, `free_service`

### payment_status (Auto-set to 'initiated')
- `initiated`, `pending`, `processing`, `completed`
- `failed`, `cancelled`, `refunded`, `disputed`, `expired`

---

## Before Production Deployment

⚠️ **IMPORTANT:** Disable anonymous payment creation before going to production:

```sql
-- Run this in Supabase SQL Editor
SELECT disable_payment_testing_policies();
```

This will:
- ✅ Drop the "Allow payment creation for testing" policy
- ✅ Drop the "Allow viewing recent payments by session" policy
- ✅ Require authentication for all payment operations

---

## Security Considerations

### Current Setup (Development/Testing)
- ✅ Anonymous users can create payments (for testing)
- ✅ Maximum payment amount: 1M XAF
- ✅ All required fields validated
- ✅ IP address and user agent captured

### Production Recommendations
1. **Disable anonymous payment creation** (run `disable_payment_testing_policies()`)
2. **Require authentication** for all payment operations
3. **Use the secure function** for payment creation
4. **Enable fraud detection** before processing payments
5. **Set up webhook notifications** for payment status changes
6. **Implement payment provider integration** (Orange Money, MTN MoMo)

---

## Files Modified

1. **Migration:** `supabase/migrations/20251106140000_fix_payments_rls_policies.sql`
2. **Documentation:** `PAYMENTS_RLS_FIX_SUMMARY.md` (this file)

---

## Next Steps

1. ✅ RLS policies fixed - payments can now be created
2. ⏭️ Test payment flow in FlutterFlow
3. ⏭️ Integrate payment provider APIs (Orange Money, MTN MoMo)
4. ⏭️ Add payment confirmation/receipt pages
5. ⏭️ Set up Firebase Cloud Function for payment processing
6. ⏭️ Before production: Run `SELECT disable_payment_testing_policies();`

---

## Troubleshooting

### Still getting 400 errors?
1. Check required fields are present:
   - `payment_reference`
   - `payment_for`
   - `payment_method`
   - `gross_amount`
   - `net_amount`

2. Verify enum values are valid (see "Valid Field Values" above)

3. Check payment amount doesn't exceed 1M XAF

4. Verify Supabase URL and API key are correct

### Need to see current policies?
```sql
SELECT * FROM pg_policies WHERE tablename = 'payments';
```

### Need to test manually?
```bash
curl -X POST \
  "https://noaeltglphdlkbflipit.supabase.co/rest/v1/payments" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "payment_reference": "TEST-20251106-001",
    "payment_for": "consultation",
    "payment_method": "cash",
    "gross_amount": 5000.00,
    "net_amount": 5000.00
  }'
```

---

**Status:** ✅ Ready for FlutterFlow integration
