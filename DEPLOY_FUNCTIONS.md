# Deploy Firebase Cloud Functions

This guide explains how to deploy the payment processing Cloud Functions.

## Prerequisites

1. **Node.js 18+ installed**
   ```bash
   node --version  # Should be 18 or higher
   ```

2. **Firebase CLI installed and logged in**
   ```bash
   firebase --version
   firebase login
   ```

3. **Stripe Account with Secret Key**
   - Get your Stripe secret key from [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
   - Use test key (`sk_test_...`) for development
   - Use live key (`sk_live_...`) for production

## Step 1: Install Function Dependencies

```powershell
cd functions
npm install
```

This installs:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Firebase Functions SDK
- `stripe` - Stripe SDK for payment processing

## Step 2: Configure Stripe Secret Key

Set your Stripe secret key in Firebase config:

```powershell
# For development (test mode)
firebase functions:config:set stripe.secret_key="sk_test_your_stripe_secret_key_here"

# For production (live mode)
firebase functions:config:set stripe.secret_key="sk_live_your_stripe_secret_key_here"
```

**Important**: Replace `your_stripe_secret_key_here` with your actual Stripe secret key.

## Step 3: Deploy Functions

From the project root directory:

```powershell
firebase deploy --only functions
```

This will deploy:
- `createPaymentIntent` - Creates Stripe payment intents
- `validatePaymentIntent` - Validates payment intent status

## Step 4: Verify Deployment

After deployment, you should see output like:

```
✔  functions[createPaymentIntent(us-central1)] Successful create operation.
✔  functions[validatePaymentIntent(us-central1)] Successful create operation.
```

You can also verify in the [Firebase Console](https://console.firebase.google.com/project/ari-s-esthetician-app/functions):
- Go to Functions section
- You should see both functions listed

## Testing the Functions

### Test in Firebase Console

1. Go to [Firebase Console → Functions](https://console.firebase.google.com/project/ari-s-esthetician-app/functions)
2. Click on a function
3. Use the "Test" tab to test with sample data

### Test from Flutter App

The functions will be automatically called when:
- User books an appointment and reaches the payment step
- Payment intent is created via `PaymentService.createPaymentIntent()`

## Troubleshooting

### Error: "Stripe secret key not configured"

**Solution**: Make sure you've set the config:
```powershell
firebase functions:config:get
```

You should see:
```
stripe:
  secret_key: sk_test_...
```

If not, set it again:
```powershell
firebase functions:config:set stripe.secret_key="sk_test_..."
```

### Error: "Function not found" or "[firebase_functions/internal] internal"

**Solution**: 
1. Make sure functions are deployed:
   ```powershell
   firebase deploy --only functions
   ```

2. Check function logs:
   ```powershell
   firebase functions:log
   ```

3. Verify function names match:
   - Function name: `createPaymentIntent`
   - Called as: `_functions.httpsCallable('createPaymentIntent')`

### Error: "Permission denied" or "Unauthorized"

**Solution**: 
1. Make sure you're logged in:
   ```powershell
   firebase login
   ```

2. Check project access:
   ```powershell
   firebase projects:list
   ```

3. Make sure you have the correct project selected:
   ```powershell
   firebase use ari-s-esthetician-app
   ```

### Error: "Node version mismatch"

**Solution**: Make sure you have Node.js 18+:
```powershell
node --version  # Should be 18.x.x or higher
```

If not, install Node.js 18+ from [nodejs.org](https://nodejs.org/)

## Local Development (Optional)

To test functions locally before deploying:

```powershell
cd functions
npm run serve
```

This starts the Firebase emulator. You'll need to configure the emulator to use your Stripe key.

## Security Notes

- ✅ Never commit Stripe secret keys to git
- ✅ Use test keys for development
- ✅ Use live keys only for production
- ✅ Functions are currently open (no auth required) for booking
- ⚠️ Consider adding authentication if needed for your use case

## Next Steps

After deploying functions:

1. **Test payment flow** in your Flutter app
2. **Monitor function logs** for any errors:
   ```powershell
   firebase functions:log --only createPaymentIntent
   ```
3. **Set up Stripe webhooks** (optional) for payment events
4. **Configure billing** in Firebase Console if needed

## Support

If you encounter issues:
1. Check function logs: `firebase functions:log`
2. Check Firebase Console for errors
3. Verify Stripe dashboard for payment attempts
4. Review function code in `functions/index.js`
