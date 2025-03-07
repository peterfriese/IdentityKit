//
// AccountService+Apple.swift
// IdentityKit
//
// Created by Peter Friese on 06.03.25.
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
