//
// AuthenticateWithAppleDialog.swift
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

import Foundation
@preconcurrency import FirebaseAuth
import Observation
import CryptoKit
import AuthenticationServices
import os

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AppleDialog")

public func authenticateWithApple() async throws -> (ASAuthorizationAppleIDCredential, String) {
  logger.debug("Starting Sign in with Apple flow")
  return try await AuthenticateWithAppleDialog().authenticate()
}

class AuthenticateWithAppleDialog: NSObject {
  private var continuation: CheckedContinuation<(ASAuthorizationAppleIDCredential, String), Error>?
  private var currentNonce: String?

  func authenticate() async throws -> (ASAuthorizationAppleIDCredential, String) {
    return try await withCheckedThrowingContinuation { continuation in
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
        continuation.resume(throwing: AuthenticationError.appleAuthenticationFailed)
        return
      }

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.performRequests()
    }
  }
}

extension AuthenticateWithAppleDialog: ASAuthorizationControllerDelegate {
  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

      let hasFullName = appleIDCredential.fullName != nil
      let hasGivenName = appleIDCredential.fullName?.givenName != nil
      let hasFamilyName = appleIDCredential.fullName?.familyName != nil
      let hasEmail = appleIDCredential.email != nil
      let hasIdentityToken = appleIDCredential.identityToken != nil
      let hasAuthorizationCode = appleIDCredential.authorizationCode != nil
      let userIdentifier = appleIDCredential.user

      logger.debug("Apple credential received - user: \(userIdentifier), hasFullName: \(hasFullName), hasGivenName: \(hasGivenName), hasFamilyName: \(hasFamilyName), hasEmail: \(hasEmail), hasIdentityToken: \(hasIdentityToken), hasAuthorizationCode: \(hasAuthorizationCode)")

      if let email = appleIDCredential.email {
        logger.info("Apple email received: \(email)")
      } else {
        logger.debug("Apple email NOT received (this is normal for subsequent sign-ins)")
      }

      if let fullName = appleIDCredential.fullName {
        let nameParts: [String] = [
          fullName.givenName.map { "givenName=\($0)" },
          fullName.familyName.map { "familyName=\($0)" },
          fullName.nickname.map { "nickname=\($0)" }
        ].compactMap { $0 }
        logger.info("Apple fullName received: \(nameParts.joined(separator: ", "))")
      } else {
        logger.debug("Apple fullName NOT received (this is normal for subsequent sign-ins)")
      }

      if let nonce = currentNonce {
        continuation?.resume(returning: (appleIDCredential, nonce))
      } else {
        logger.error("No nonce available when Apple credential received")
        continuation?.resume(throwing: AuthenticationError.appleAuthenticationFailed)
      }
    }
    else {
      logger.error("Authorization failed: credential is not ASAuthorizationAppleIDCredential")
      continuation?.resume(throwing: AuthenticationError.missingAppleIDToken)
    }
    continuation = nil
  }

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithError error: Error) {
    logger.error("Sign in with Apple failed: \(error.localizedDescription)")
    continuation?.resume(throwing: AuthenticationError.signInFailed(underlying: error))
    continuation = nil
  }
}
