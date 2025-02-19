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

class AuthenticateWithAppleHandler: NSObject {
  private var continuation: CheckedContinuation<Result<(ASAuthorizationAppleIDCredential, String), Error>, Never>?
  private var currentNonce: String?

  func authenticate() async -> Result<(ASAuthorizationAppleIDCredential, String), Error> {
    await withCheckedContinuation { continuation in
      self.continuation = continuation

      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]

      do {
        let nonce = try CryptoUtils.randomNonceString()
        currentNonce = nonce
        request.nonce = CryptoUtils.sha256(nonce)
      }
      catch {
        print("Error when creating a nonce: \(error.localizedDescription)")
      }

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.performRequests()
    }
  }
}

extension AuthenticateWithAppleHandler: ASAuthorizationControllerDelegate {
  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      if let nonce = currentNonce {
        continuation?.resume(returning: .success((appleIDCredential, nonce)))
      } else {
        continuation?.resume(returning: .failure(NSError(domain: "", code: -1,
                                                         userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])))
      }
    }
    else {
      continuation?.resume(returning: .failure(NSError(domain: "", code: -1,
                                                       userInfo: [NSLocalizedDescriptionKey: "Could not get Apple ID credentials"])))
    }
    continuation = nil
  }

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithError error: Error) {
    continuation?.resume(returning: .failure(error))
    continuation = nil
  }
}


extension AuthenticationService {
  @MainActor
  func signInWithApple() async -> Bool {
    let handler = AuthenticateWithAppleHandler()
    let result = await handler.authenticate()

    switch result {
    case .failure(let error):
      errorMessage = error.localizedDescription
      return false

    case .success(let (appleIDCredential, nonce)):
      guard let appleIDToken = appleIDCredential.identityToken else {
        print("Unable to fetch identify token.")
        return false
      }

      guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
        print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
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
