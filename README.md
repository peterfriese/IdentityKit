# IdentityKit

IdentityKit is a Swift package that provides a comprehensive authentication solution for your iOS apps. It seamlessly integrates with Firebase Authentication and offers multiple authentication methods, including email/password, Apple Sign-In, and more.

![IdentityKit Screenshot](./assets/screenshots/screenshot.png)

## Features

- 🔐 Multiple authentication methods:
  - Email and password authentication
  - Apple Sign-In
  - Google Sign-In
  - *(More methods coming soon)*
- 🔄 Complete user lifecycle management:
  - Sign up
  - Sign in
  - Password reset
  - Account deletion
  - Account upgrade (guest → full account)
- 🎨 Customizable UI components
- 🛡️ Robust error handling with clear, localized messages
- 📱 iOS 26+ support
- 💻 macOS 26+ support
- 🔌 Firebase Authentication integration

## Requirements

- iOS 26+
- macOS 26+
- Swift 6.2+
- Xcode 26+

## Installation

### Swift Package Manager

Add IdentityKit to your project using Swift Package Manager by adding it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/peterfriese/IdentityKit.git", from: "0.3.1")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages
2. Paste the repository URL: `https://github.com/peterfriese/IdentityKit.git`
3. Click Next and select the version you want to use

## Firebase Setup

1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your Firebase project
3. Download the `GoogleService-Info.plist` file and add it to your app
4. Enable the authentication methods you want to use in the Firebase Console

### Google Sign-In Setup

If you want to use Google Sign-In, additional configuration is required:

1. **Enable Google Sign-In in Firebase Console**:
   - Go to Authentication → Sign-in method
   - Enable "Google"

2. **Configure URL Schemes**:
   - Open your `GoogleService-Info.plist` file
   - Find the `REVERSED_CLIENT_ID` value (e.g., `com.googleusercontent.apps.123456789-abcdef`)
   - Add this as a URL scheme in your app's Info.plist:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>YOUR_REVERSED_CLIENT_ID</string>
         </array>
       </dict>
     </array>
     ```

3. **Handle URL callback**:
   Add to your AppDelegate (iOS) or App (macOS):
   ```swift
   func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       return GIDSignIn.sharedInstance.handle(url)
   }
   ```

## Quick Start

### Initialize Firebase

```swift
import FirebaseCore
import IdentityKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
```

### Present Authentication Screen

```swift
import SwiftUI
import IdentityKit

struct ContentView: View {
    @State private var showAuthScreen = false
    
    var body: some View {
        Button("Sign In") {
            showAuthScreen = true
        }
        .sheet(isPresented: $showAuthScreen) {
            AuthenticationScreen()
        }
    }
}
```

### Enable Authentication Providers

You can specify which authentication providers to enable in your application using SwiftUI view modifiers:

```swift
import SwiftUI
import IdentityKit

struct ContentView: View {
    @State private var showAuthScreen = false
    
    var body: some View {
        Button("Sign In") {
            showAuthScreen = true
        }
        .sheet(isPresented: $showAuthScreen) {
            AuthenticationScreen()
                .authenticationProviders([.email, .apple])
        }
    }
}
```

Remember to enable these same authentication providers in the Firebase Console to ensure they work properly.

### Handle Authentication State

```swift
import SwiftUI
import IdentityKit

struct MainView: View {
    @StateObject private var authService = AuthenticationService.shared

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Show authenticated content
                AuthenticatedView()
            } else {
                // Show authentication screen
                AuthenticationScreen()
            }
        }
        .onAppear {
            // Check authentication state
            authService.updateAuthenticationState()
        }
    }
}
```

### Account Screen

IdentityKit provides a built-in Account screen that displays the user's account status and provides options to upgrade from guest or sign out from a full account:

```swift
import SwiftUI
import IdentityKit

struct ContentView: View {
    @State private var showAccount = false

    var body: some View {
        Button("Account") {
            showAccount = true
        }
        .sheet(isPresented: $showAccount) {
            AccountView { error in
                // Handle upgrade failures
                print("Upgrade failed: \(error.localizedDescription)")
            }
            .environment(AuthenticationService.shared)
        }
    }
}
```

The Account screen displays:
- **Guest users**: Warning about device-only data, benefits of upgrading, and an "Upgrade to Full Account" button
- **Authenticated users**: Email address, verification status, sign-in methods (as pills), "Sign Out" and "Delete Account" buttons

## Advanced Usage

### Custom Authentication UI

You can customize the authentication UI by creating your own views and using IdentityKit's authentication services:

```swift
import SwiftUI
import IdentityKit

struct CustomAuthView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textContentType(.password)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button("Sign In") {
                Task {
                    do {
                        try await authService.signInWithEmail(email: email, password: password)
                    } catch let error as AuthenticationError {
                        errorMessage = error.localizedDescription
                    } catch {
                        errorMessage = "An unknown error occurred"
                    }
                }
            }
            
            Button("Sign In with Apple") {
                Task {
                    do {
                        try await authService.signInWithApple()
                    } catch let error as AuthenticationError {
                        errorMessage = error.localizedDescription
                    } catch {
                        errorMessage = "An unknown error occurred"
                    }
                }
            }
            .buttonStyle(SocialAuthenticationButtonStyle(provider: .apple))
        }
        .padding()
    }
}
```

### Error Handling

IdentityKit provides a comprehensive `AuthenticationError` enum with clear, localized error messages:

```swift
import IdentityKit

do {
    try await authService.signInWithEmail(email: email, password: password)
} catch let error as AuthenticationError {
    switch error {
    case .invalidCredentials:
        // Show "Invalid email or password"
    case .signInFailed(let underlying):
        // Show "Failed to sign in: \(underlying.localizedDescription)"
    case .upgradeCancelled:
        // Show "Account upgrade was not completed"
    // ... handle other cases
    }
}
```

**Available error cases:**
- `invalidCredentials` - Invalid email or password
- `signInFailed(underlying:)` - Sign in failed with underlying error
- `signUpFailed(underlying:)` - Sign up failed with underlying error
- `credentialAlreadyInUse(underlying:)` - Credentials already linked to another account
- `userDeletionFailed(underlying:)` - Account deletion failed
- `reauthenticationRequired` - User needs to re-authenticate
- `upgradeCancelled` - Guest account upgrade was not completed

All errors conform to Swift's `LocalizedError` protocol for automatic localizedDescription support.

## License

IdentityKit is available under the MIT license. See the LICENSE file for more info.

## Contribution

Contributions are welcome! Please feel free to submit a Pull Request. 