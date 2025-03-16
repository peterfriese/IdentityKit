import Foundation

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
    }
  }
}
