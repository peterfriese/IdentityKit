//
// AccountService+Email.swift
// IdentityKit
//
// Created by Peter Friese on 7.3.2025.
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
import OSLog

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "EmailAuthentication")

protocol EmailPasswordOperationReauthentication { }
extension EmailPasswordOperationReauthentication {
  func reauthenticate() async throws -> AuthenticationToken {
    logger.debug("Attempting to reauthenticate with Email and password")

    guard let user = Auth.auth().currentUser else {
      logger.error("Reauthentication failed: No current user found")
      throw AuthenticationError.reauthenticationRequired
    }

    guard let email = user.email else {
      logger.error("Reauthentication failed: Current user has no email")
      throw AuthenticationError.invalidCredentials
    }

    do {
      let password = try await confirmPassword(for: email)

      let credential = EmailAuthProvider.credential(withEmail: email, password: password)
      try await Auth.auth().currentUser?.reauthenticate(with: credential)

      logger.info("Successfully reauthenticated user with email")
      return .firebase("")
    } catch {
      logger.error("Reauthentication failed: \(error.localizedDescription)")
      throw AuthenticationError.signInFailed(underlying: error)
    }
  }
}

class EmailPasswordDeleteUserOperation: DeleteUserOperation, EmailPasswordOperationReauthentication {
}
