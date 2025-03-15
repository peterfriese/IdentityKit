//
// AuthenticationService+Apple.swift
// IdentityKit
//
// Created by Peter Friese on 17.2.2025
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

@preconcurrency import FirebaseAuth
import Observation
import CryptoKit
import AuthenticationServices

extension Data {
  var utf8String: String? {
    return String(data: self, encoding: .utf8)
  }
}

extension ASAuthorizationAppleIDCredential {
  var authorizationCodeString: String? {
    return authorizationCode?.utf8String
  }

  var idTokenString: String? {
    return identityToken?.utf8String
  }
}

extension AuthenticationService {
  @MainActor
  @discardableResult
  func signInWithApple() async throws -> Bool {
    let (appleIDCredential, nonce) = try await authenticateWithApple()

    guard let idTokenString = appleIDCredential.idTokenString else {
      throw AuthenticationError.missingAppleIDToken
    }

    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                   rawNonce: nonce,
                                                   fullName: appleIDCredential.fullName)

    do {
      try await authenticateUser(with: credential)
      return true
    }
    catch {
      throw AuthenticationError.signInFailed(underlying: error)
    }
  }
}
