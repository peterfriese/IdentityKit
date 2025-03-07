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
import os

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AppleAuthentication")

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
    logger.debug("Trying to reauth with Sign in with Apple")
    let (appleIDCredential, nonce) = try await authenticateWithApple()
    
    guard let idTokenString = appleIDCredential.idTokenString else {
      logger.error("Unable to fetch identity token string")
      throw AuthenticationError.missingAppleIDToken
    }
    
    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                   rawNonce: nonce,
                                                   fullName: appleIDCredential.fullName)
    
    do {
      try await Auth.auth().currentUser?.reauthenticate(with: credential)
      return .apple(appleIDCredential, nonce)
    } catch {
      throw AuthenticationError.reauthenticationRequired
    }
  }
}

class AppleDeleteUserOperation: DeleteUserOperation, AppleOperationReauthentication {
  func performOperation(on user: User, with token: AuthenticationToken? = nil) async throws {
    guard case .apple(let appleIDCredential, _) = token else {
      throw AuthenticationError.reauthenticationRequired
    }
    
    guard let authorizationCodeString = appleIDCredential.authorizationCodeString else {
      throw AuthenticationError.missingAuthorizationCode
    }
    
    // First try to revoke the token
    do {
      try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCodeString)
      logger.info("Revoked Apple ID token")
    } catch {
      // If token revocation fails
      logger.error("Token revocation failed: \(error.localizedDescription)")
      
      // For non-Apple ID users, we can proceed with deletion even if token revocation fails
      if !user.isAppleIDUser {
        logger.warning("Continuing with user deletion as user is not an Apple ID user")
      } else {
        // For Apple ID users, token revocation failure is critical
        throw AuthenticationError.tokenRevocationFailed(underlying: error)
      }
    }
    
    // Now try to delete the user
    do {
      try await user.delete()
      logger.info("Deleted user")
    } catch {
      logger.error("User deletion failed: \(error.localizedDescription)")
      throw AuthenticationError.userDeletionFailed(underlying: error)
    }
  }
}
