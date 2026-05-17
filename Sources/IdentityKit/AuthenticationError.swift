import Foundation

/// An error that can occur during authentication operations.
///
/// This enum covers various authentication scenarios including sign-in failures,
/// credential issues, Apple/Google authentication problems, and storage errors.
///
/// ## Topics
/// ### Error Cases
/// - ``signInFailed(underlying:)``
/// - ``signUpFailed(underlying:)``
/// - ``invalidCredentials``
/// - ``credentialAlreadyInUse(underlying:)``
/// - ``missingAppleIDToken``
/// - ``missingAuthorizationCode``
/// - ``appleAuthenticationFailed``
/// - ``userDeletionFailed(underlying:)``
/// - ``reauthenticationRequired``
/// - ``tokenRevocationFailed(underlying:)``
/// - ``upgradeCancelled``
/// - ``googleSignInFailed(underlying:)``
/// - ``googleSignInCancelled``
/// - ``missingGoogleIDToken``
/// - ``storageNotEnabled``
/// - ``uploadFailed(underlying:)``
/// - ``storageError(underlying:)``
public enum AuthenticationError: LocalizedError {
  case signInFailed(underlying: Error)
  case signUpFailed(underlying: Error)
  case invalidCredentials
  case credentialAlreadyInUse(underlying: Error)
  case missingAppleIDToken
  case missingAuthorizationCode
  case appleAuthenticationFailed
  case userDeletionFailed(underlying: Error)
  case reauthenticationRequired
  case tokenRevocationFailed(underlying: Error)
  case upgradeCancelled
  case googleSignInFailed(underlying: Error?)
  case googleSignInCancelled
  case missingGoogleIDToken
  case storageNotEnabled
  case uploadFailed(underlying: Error)
  case storageError(underlying: Error)

  public var errorDescription: String? {
    switch self {
    case .signInFailed(let error):
      return "Failed to sign in: \(error.localizedDescription)"
    case .signUpFailed(let error):
      return "Failed to create account: \(error.localizedDescription)"
    case .invalidCredentials:
      return "Invalid email or password"
    case .credentialAlreadyInUse(underlying: let error):
      return "Credentials already in use: \(error.localizedDescription)"
    case .missingAppleIDToken:
      return "Could not retrieve Apple ID token"
    case .missingAuthorizationCode:
      return "Could not retrieve Apple authorization code"
    case .appleAuthenticationFailed:
      return "Authentication with Apple failed"
    case .userDeletionFailed(let error):
      return "Failed to delete account: \(error.localizedDescription)"
    case .reauthenticationRequired:
      return "Please sign in again to continue"
    case .tokenRevocationFailed(let error):
      return "Failed to revoke authentication token: \(error.localizedDescription)"
    case .upgradeCancelled:
      return "Account upgrade was not completed"
    case .googleSignInFailed(let underlying):
      if let underlying {
        return "Failed to sign in with Google: \(underlying.localizedDescription)"
      }
      return "Failed to sign in with Google"
    case .googleSignInCancelled:
      return "Google sign in was cancelled"
    case .missingGoogleIDToken:
      return "Could not retrieve Google ID token"
    case .storageNotEnabled:
      return "Image upload unavailable. Please enable Cloud Storage in Firebase Console."
    case .uploadFailed(let underlying):
      return "Failed to upload image: \(underlying.localizedDescription)"
    case .storageError(let underlying):
      return "Storage error: \(underlying.localizedDescription)"
    }
  }
}
