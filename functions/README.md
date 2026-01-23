# Firebase Cloud Functions

This directory contains Firebase Cloud Functions for the Aris Esthetician App, specifically for handling Stripe payment processing.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Stripe Secret Key

You need to set your Stripe secret key in Firebase config. You can do this in two ways:

#### Option A: Using Firebase CLI (Recommended)

```bash
firebase functions:config:set stripe.secret_key="sk_test_your_stripe_secret_key_here"
```

For production:
```bash
firebase functions:config:set stripe.secret_key="sk_live_your_stripe_secret_key_here"
```

#### Option B: Using Environment Variables (Local Development)

Create a `.env` file in the `functions` directory:
```
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
```

**Note**: The `.env` file is gitignored for security.

### 3. Deploy Functions

```bash
# From project root
firebase deploy --only functions

# Or from functions directory
cd functions
npm run deploy
```

## Available Functions

### `createPaymentIntent`

Creates a Stripe payment intent for processing payments.

**Request Parameters:**
- `amount` (number, required): Amount in cents
- `currency` (string, required): Currency code (e.g., 'usd')
- `customerEmail` (string, optional): Customer email for receipt
- `metadata` (object, optional): Additional metadata

**Returns:**
- `id`: Payment intent ID
- `clientSecret`: Client secret for payment confirmation
- `created`: Creation timestamp
- `livemode`: Whether in live mode
- `amount`: Amount in cents
- `currency`: Currency code
- `status`: Payment intent status

### `validatePaymentIntent`

Validates a payment intent status.

**Request Parameters:**
- `paymentIntentId` (string, required): Stripe payment intent ID

**Returns:**
- `valid`: Whether payment intent is in a valid state
- `status`: Payment intent status
- `amount`: Amount in cents
- `currency`: Currency code
- `id`: Payment intent ID

## Local Development

To test functions locally:

```bash
cd functions
npm run serve
```

This starts the Firebase emulator. You can then test functions at:
- `http://localhost:5001/ari-s-esthetician-app/us-central1/createPaymentIntent`
- `http://localhost:5001/ari-s-esthetician-app/us-central1/validatePaymentIntent`

## Security Notes

- Never commit Stripe secret keys to version control
- Use test keys for development, live keys for production
- The functions handle authentication optionally (currently open for booking)
- Consider adding authentication requirements if needed

## Troubleshooting

### Error: "Stripe secret key not configured"

Make sure you've set the Stripe secret key using one of the methods above.

### Error: "Function not found"

Make sure you've deployed the functions:
```bash
firebase deploy --only functions
```

### Error: "Permission denied"

Check that your Firebase project has Cloud Functions enabled and you have the correct permissions.
