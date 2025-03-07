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

extension ASAuthorizationAppleIDCredential {
  var authorizationCodeString: String? {
    guard let authorizationCode else { return nil }
    return String(data: authorizationCode, encoding: .utf8)
  }

  var idTokenString: String? {
    guard let identityToken else { return nil }
    return String(data: identityToken, encoding: .utf8)
  }
}

extension AuthenticationService {
  @MainActor
  func signInWithApple() async -> Bool {
    let result = await authenticateWithApple()

    switch result {
    case .failure(let error):
      errorMessage = error.localizedDescription
      return false

    case .success(let (appleIDCredential, nonce)):
      guard let idTokenString = appleIDCredential.idTokenString else {
        print("Unable to fetch identity token string.")
        return false
      }

      let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                     rawNonce: nonce,
                                                     fullName: appleIDCredential.fullName)

      do {
        try await Auth.auth().signIn(with: credential)
        return true
      }
      catch {
        print("Error authenticating: \(error.localizedDescription)")
        return false
      }
    }
  }
}
