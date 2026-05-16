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
import os

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AppleAuthService")

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

    let displayNameFromApple: String?
    if let fullName = appleIDCredential.fullName {
      let nameParts = [fullName.givenName, fullName.familyName].compactMap { $0 }
      displayNameFromApple = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")
    } else {
      displayNameFromApple = nil
    }

    logger.debug("Creating Firebase credential - displayNameFromApple: \(String(describing: displayNameFromApple)), emailFromApple: \(String(describing: appleIDCredential.email))")

    guard let idTokenString = appleIDCredential.idTokenString else {
      logger.error("No identity token from Apple")
      throw AuthenticationError.missingAppleIDToken
    }

    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                   rawNonce: nonce,
                                                   fullName: appleIDCredential.fullName)

    do {
      // Check if we have an existing authenticated non-guest user
      let hasExistingUser = Auth.auth().currentUser != nil && !Auth.auth().currentUser!.isAnonymous

      if hasExistingUser {
        // Link the credential to existing user
        try await link(with: credential)
        logger.info("Successfully linked Apple credential to Firebase user")
      } else {
        // Sign in fresh - this is needed after account deletion to get a clean session
        try await signIn(with: credential)
        logger.info("Successfully signed in with Apple credential")
      }

      // Force sync of auth state - Firebase's auth listener may not fire reliably
      // after account deletion and re-authentication
      updateAuthenticationState()
      refreshUser()

      // Firebase doesn't automatically store displayName from Apple credentials
      // We need to manually update the user's profile when Apple provides the name
      // (Apple only provides name/email on first authorization)
      if let displayName = displayNameFromApple, !displayName.isEmpty {
        logger.debug("Saving displayName to Firebase user profile: \(displayName)")
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        try await changeRequest?.commitChanges()
        logger.info("Successfully saved displayName to Firebase user profile")

        // Force reload from Firebase to get the updated profile
        try await Auth.auth().currentUser?.reload()

        // Wait briefly for Firebase to propagate the change, then sync
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        updateAuthenticationState()
        refreshUser()
      }

      // Log the Firebase user state after sign-in
      if let user = Auth.auth().currentUser {
        logger.debug("Firebase user after sign-in - uid: \(user.uid), displayName: \(String(describing: user.displayName)), email: \(String(describing: user.email)), isAnonymous: \(user.isAnonymous)")
      }

      return true
    }
    catch let error as NSError where error.credentialAlreadyInUse {
      logger.info("Apple credential already in use, attempting to sign in with existing credential")

      if let updatedCredential = error.userInfo[AuthErrors.userInfoUpdatedCredentialKey] as? AuthCredential {
        // When credential is already in use, we need to sign out first and then sign in
        // This ensures a clean Firebase session after account deletion
        try Auth.auth().signOut()
        logger.info("Signed out to clear stale session")

        try await signIn(with: updatedCredential)
        logger.info("Successfully signed in with existing Apple credential")

        // Force sync of auth state - Firebase's auth listener may not fire reliably
        // after account deletion and re-authentication
        updateAuthenticationState()
        refreshUser()

        // Even when signing in with existing credential, we might want to save the name
        // if it's the first time we have it and it's not already saved
        if let displayName = displayNameFromApple, !displayName.isEmpty {
          let currentDisplayName = Auth.auth().currentUser?.displayName
          if currentDisplayName == nil || currentDisplayName?.isEmpty == true {
            logger.debug("Saving displayName to Firebase user profile (re-auth): \(displayName)")
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = displayName
            try await changeRequest?.commitChanges()
            logger.info("Successfully saved displayName to Firebase user profile")

            // Force reload from Firebase to get the updated profile
            try await Auth.auth().currentUser?.reload()

            // Wait briefly for Firebase to propagate the change, then sync
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            updateAuthenticationState()
            refreshUser()
          }
        }

        // Log the Firebase user state after sign-in with existing credential
        if let user = Auth.auth().currentUser {
          logger.debug("Firebase user after existing credential sign-in - uid: \(user.uid), displayName: \(String(describing: user.displayName)), email: \(String(describing: user.email)), isAnonymous: \(user.isAnonymous)")
        }

        return true
      }
      else {
        logger.error("credentialAlreadyInUse error but no updated credential available")
        throw AuthenticationError.credentialAlreadyInUse(underlying: error)
      }
    }
    catch {
      logger.error("Sign in with Apple failed: \(error.localizedDescription)")
      throw AuthenticationError.signInFailed(underlying: error)
    }
  }
}
