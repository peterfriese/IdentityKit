//
// AccountService.swift
// IdentityKit
//
// Created by Peter Friese on 26.02.25.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Observation
import AuthenticationServices
@preconcurrency import FirebaseAuth

extension User {
  var isAppleIDUser: Bool {
    get {
      providerData.contains { $0.providerID == "apple.com" }
    }
  }
}

enum IdentityKitCredential {
  case apple(ASAuthorizationAppleIDCredential)
}

@MainActor
@Observable
final public class AccountService {
  public static let shared = AccountService()

  private init() {
  }

  deinit {
  }

  public func deleteAccount() async throws -> Bool {
    guard let user = Auth.auth().currentUser else {
      return false
    }

    let operation: DeleteUserOperation = if user.isAppleIDUser {
      AppleDeleteUserOperation()
    }
    else {
      EmailPasswordDeleteUserOperation()
    }

    try await operation()

    //
    //    try await withAuthentication {
    //      try await user.delete()
    //    }

    return true
  }

  func withAuthentication(_ operation: @escaping () async throws -> Void) async throws {
    // First attempt
    do {
      try await operation()
      return
    }
    catch let error as NSError {
      // Only retry if we need to re-authenticate
      guard error.domain == AuthErrorDomain && error.code == AuthErrorCode.requiresRecentLogin.rawValue else {
        throw error
      }

      // Get current user
      guard let user = Auth.auth().currentUser else {
        throw error
      }

      do {
        // Re-authenticate based on provider
        if user.isAppleIDUser {
          try await AppleAuthenticationStrategy.default.reauthenticate()
        }
        else {
          try await EmailPasswordAuthenticationStrategy.default.reauthenticate()
        }

        // Second attempt after re-authentication
        try await operation()
      }
      catch {
        // If re-authentication fails or the second attempt fails,
        // throw the new error instead of the original one
        throw error
      }
    }
  }
}

protocol AuthenticationStrategy {
  func reauthenticate() async throws
}

@MainActor
final class EmailPasswordAuthenticationStrategy: AuthenticationStrategy {
  public static let `default` = EmailPasswordAuthenticationStrategy()

  func reauthenticate() async throws {
  }
}

@MainActor
final class AppleAuthenticationStrategy: AuthenticationStrategy {
  public static let `default` = AppleAuthenticationStrategy()

  func reauthenticate() async throws {
  }
}

enum AuthenticationToken {
  case apple(ASAuthorizationAppleIDCredential, String)
  case firebase(String)
}

protocol AuthenticatedOperation {
  func callAsFunction() async throws
  func reauthenticate() async throws -> AuthenticationToken
  func performOperation(on user: User, with token: AuthenticationToken?) async throws
}

extension AuthenticatedOperation {
  func callAsFunction() async throws {
    guard let user = Auth.auth().currentUser else {
      return
    }

    do {
      try await performOperation(on: user, with: nil)
    }
    catch let error as NSError {
      guard error.domain == AuthErrorDomain && error.code == AuthErrorCode.requiresRecentLogin.rawValue else {
        throw error
      }

      let token = try await reauthenticate()
      try await performOperation(on: user, with: token)
    }
  }
}

protocol DeleteUserOperation: AuthenticatedOperation { }

extension DeleteUserOperation {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    try await user.delete()
  }
}

protocol EmailPasswordOperationReauthentication { }
extension EmailPasswordOperationReauthentication {
  func reauthenticate() async throws -> AuthenticationToken {
    print("Trying to reauth with Email and password")
    // TODO: at this point, we need to show an email sign in form
    let credential = EmailAuthProvider.credential(withEmail: "test@test.com", password: "test1234")
    try await Auth.auth().currentUser?.reauthenticate(with: credential)

    return .firebase("")
  }
}

protocol AppleOperationReauthentication { }
extension AppleOperationReauthentication {
  func reauthenticate() async throws -> AuthenticationToken {
    print("Trying to reauth with Sign in with Apple")
    let handler = AuthenticateWithAppleHandler()
    let result = await handler.authenticate()

    guard case .success(let (appleIDCredential, nonce)) = result else {
      throw NSError(domain: "AppleAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID credential"])
    }

    guard let appleIDToken = appleIDCredential.identityToken else {
      print("Unable to fetch identify token.")
      throw NSError(domain: "AppleAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identify token."])
    }

    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
      throw NSError(domain: "AppleAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialise token string from data."])
    }

    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                   rawNonce: nonce,
                                                   fullName: appleIDCredential.fullName)

    try await Auth.auth().currentUser?.reauthenticate(with: credential)
    return .apple(appleIDCredential, nonce)
  }
}

class EmailPasswordDeleteUserOperation: DeleteUserOperation, EmailPasswordOperationReauthentication {
}

class AppleDeleteUserOperation: DeleteUserOperation, AppleOperationReauthentication {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    guard case .apple(let appleIDCredential, let nonce) = token else {
      throw NSError(domain: AuthErrorDomain, code: AuthErrorCode.requiresRecentLogin.rawValue)
    }

    guard let authorizationCode = appleIDCredential.authorizationCode,
          let authCode = String(data: authorizationCode, encoding: .utf8) else {
      throw NSError(domain: "AppleAuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract authorization code"])
    }

    guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
      print("Unable to serialize auth code string from data: \(authorizationCode.debugDescription)")
      throw NSError(domain: "AppleAuthError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize auth code string"])
    }

    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
    print("Revoked Apple ID token")

    try await user.delete()
    print("Deleted user")
  }
}
