//
// AccountService+Password.swift
// IdentityKit
//
// Created by Peter Friese on 15.05.26
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
//

import Observation
@preconcurrency import FirebaseAuth
import OSLog

private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "PasswordService")

extension AccountService {
  public func changePassword(currentPassword: String?, newPassword: String) async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    if let currentPassword {
      let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
      try await user.reauthenticate(with: credential)
    }

    try await user.updatePassword(to: newPassword)
    logger.info("Password changed successfully")
  }

  public func setPassword(_ password: String) async throws {
    guard let user = Auth.auth().currentUser else {
      throw AuthenticationError.invalidCredentials
    }

    try await user.updatePassword(to: password)
    logger.info("Password set successfully")
  }
}