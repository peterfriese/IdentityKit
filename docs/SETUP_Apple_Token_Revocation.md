# Sign in with Apple - Token Revocation Setup

This guide covers the steps to properly configure Sign in with Apple to support account deletion with token revocation, as required by Apple's App Store Review Guidelines (5.1.1(v)).

## Prerequisites

- Apple Developer Account
- Firebase Project with Authentication enabled
- iOS app that supports Sign in with Apple

## Setup Steps

### 1. Apple Developer Portal Configuration

#### 1.1 Create or Configure an App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. If you have an existing App ID, configure it. If not, create a new one:
   - Select **App IDs** → **App**
   - Enable **Sign in with Apple**

#### 1.2 Create a Service ID (for web/callback)

1. In Identifiers, click the **+** button
2. Select **Services IDs** → **Continue**
3. Description: `Firebase Auth Callback`
4. Identifier: `com.yourteam.yourapp` (your Service ID)
5. Enable **Sign in with Apple** → Continue → Register

#### 1.3 Configure Domain and Privacy URL

1. Click on your Service ID
2. Enable **Sign in with Apple**
3. Click **Configure**:
   - **Domains and Subdomains**: Add your Firebase auth domain (e.g., `yourapp.firebaseapp.com`)
   - **Return URLs**: Add `https://yourapp.firebaseapp.com/__/auth/handler`
   - **Privacy Notice URL**: Add your privacy policy URL

#### 1.4 Create a Privacy Policy Webpage

You need a publicly accessible webpage at your privacy policy URL that includes:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy</title>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p>Your app's privacy policy content here...</p>
</body>
</html>
```

Host this at your privacy policy URL (e.g., `https://yourapp.com/privacy.html`)

### 2. Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Authentication** → **Sign-in method**
3. Enable **Apple** provider
4. Configure:
   - **Service ID**: Your Service ID from Apple Developer Portal
   - **Apple Team ID**: Your Apple Team ID (found in Apple Developer Portal membership)
   - **Private Key**: Download the private key for your Sign in with Apple key
   - **Key ID**: The ID of the private key you downloaded
   - **OAuth code flow**: Enable this

### 3. iOS App Configuration

#### 3.1 Enable Sign in with Apple in Xcode

1. Open your project in Xcode
2. Select your app target → **Signing & Capabilities**
3. Enable **Sign in with Apple**

#### 3.2 Configure Capabilities

Ensure your app has the appropriate capabilities enabled for your app type.

### 4. Token Revocation Implementation

IdentityKit handles token revocation automatically. When a user deletes their account:

1. **Reauthenticate**: User must re-authenticate with Apple (within 5 minutes)
2. **Revoke Token**: Call `Auth.auth().revokeToken(withAuthorizationCode:)` with the Apple authorization code
3. **Delete User**: Call `user.delete()` to remove the Firebase user

The implementation is in `AccountService+Apple.swift`:

```swift
class AppleDeleteUserOperation: DeleteUserOperation, AppleOperationReauthentication {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    guard case .apple(let appleIDCredential, _) = token else {
      throw AuthenticationError.reauthenticationRequired
    }
    
    guard let authorizationCodeString = appleIDCredential.authorizationCodeString else {
      throw AuthenticationError.missingAuthorizationCode
    }
    
    // Revoke the Apple token
    try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCodeString)
    
    // Delete the Firebase user
    try await user.delete()
  }
}
```

## Testing Token Revocation

To test the token revocation flow:

1. Sign in with Apple in your app
2. Navigate to Account → Delete Account
3. Complete the reauthentication flow
4. Verify:
   - Apple token is revoked (check Apple Developer Portal → Users and Access)
   - Firebase user is deleted
   - User is signed out of the app

## Troubleshooting

### "Invalid client_id" error
- Verify your Service ID matches exactly in both Apple Developer Portal and Firebase Console

### "Invalid client_secret" error
- Ensure your private key and key ID are correct
- Regenerate the private key if needed

### "Token revocation failed" error
- The authorization code may have expired (codes are valid for a short time)
- Ensure the user has re-authenticated within 5 minutes

### User not redirected back to app
- Check your URL schemes in Info.plist
- Verify the return URL matches exactly

## References

- [Apple Sign in with Apple Documentation](https://developer.apple.com/documentation/sign_in_with_apple)
- [Firebase Apple Authentication](https://firebase.google.com/docs/auth/ios/apple)
- [Apple App Store Review Guidelines 5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#5.1.1)