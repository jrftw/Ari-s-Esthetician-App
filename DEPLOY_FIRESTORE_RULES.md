# Deploy Firestore Security Rules

This guide explains how to deploy the Firestore security rules to your Firebase project.

## Prerequisites

1. **Firebase CLI Installed**
   ```bash
   npm install -g firebase-tools
   ```

2. **Logged In to Firebase**
   ```bash
   firebase login
   ```

3. **Project Initialized**
   ```bash
   firebase use ari-s-esthetician-app
   ```
   Or if not initialized:
   ```bash
   firebase init firestore
   ```

## Deploy Rules

### Deploy Rules Only

```bash
firebase deploy --only firestore:rules
```

### Deploy Rules and Indexes

```bash
firebase deploy --only firestore
```

This will deploy both:
- Security rules (`firestore.rules`)
- Indexes (`firestore.indexes.json`)

## Verify Deployment

1. **Check Firebase Console**
   - Go to [Firestore Rules](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore/rules)
   - Verify the rules match your local `firestore.rules` file

2. **Test Rules**
   - Use the Rules Playground in Firebase Console
   - Test various scenarios:
     - Public read of services
     - Admin write to services
     - Public create of appointments
     - Admin read of appointments

## Rules Overview

The deployed rules provide:

- **Public Access**: Services, business settings, availability (read-only)
- **Authenticated Access**: Users can read their own data
- **Admin Access**: Full CRUD for all collections
- **Booking Access**: Public can create appointments (for client booking)

## Troubleshooting

### "Permission denied" errors

1. Check that rules are deployed:
   ```bash
   firebase firestore:rules:get
   ```

2. Verify user role in Firestore:
   - Check `users/{userId}` document
   - Verify `role` field is set to `"admin"`

3. Test in Rules Playground:
   - Use Firebase Console → Firestore → Rules → Rules Playground
   - Simulate different user scenarios

### Rules not updating

1. Clear Firebase cache:
   ```bash
   firebase logout
   firebase login
   ```

2. Force deploy:
   ```bash
   firebase deploy --only firestore:rules --force
   ```

## Development vs Production

For development, you might want more permissive rules. For production, ensure:

- Admin routes are properly protected
- Client data is not publicly readable
- Payment information is admin-only
- Business settings are read-only for public

## Security Best Practices

1. **Review Rules Regularly**
   - Audit rules quarterly
   - Test edge cases
   - Monitor Firestore usage logs

2. **Least Privilege**
   - Only grant necessary permissions
   - Use helper functions for common checks
   - Validate data in rules

3. **Test Before Deploy**
   - Use Rules Playground
   - Test with different user roles
   - Verify error messages

4. **Monitor Access**
   - Review Firestore access logs
   - Set up alerts for unusual activity
   - Track failed authentication attempts
