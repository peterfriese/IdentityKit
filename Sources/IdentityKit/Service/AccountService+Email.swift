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

protocol EmailPasswordOperationReauthentication { }
extension EmailPasswordOperationReauthentication {
  func reauthenticate() async throws -> AuthenticationToken {
    print("Trying to reauth with Email and password")

    guard let user = Auth.auth().currentUser else {
      throw NSError(domain: "", code: 0, userInfo: nil)
    }

    guard let email = user.email else {
      throw NSError(domain: "", code: 0, userInfo: nil)
    }

    let password = try await confirmPassword(for: email)

    let credential = EmailAuthProvider.credential(withEmail: email, password: password)
    try await Auth.auth().currentUser?.reauthenticate(with: credential)

    return .firebase("")
  }
}

class EmailPasswordDeleteUserOperation: DeleteUserOperation, EmailPasswordOperationReauthentication {
}
