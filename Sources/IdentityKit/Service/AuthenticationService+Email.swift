//
// AuthenticationService+Email.swift
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

extension AuthenticationService {
  public func signIn(withEmail email: String, password: String) async throws {
    authenticationState = .authenticating
    do {
      try await Auth.auth().signIn(withEmail: email, password: password)
    }
    catch {
      authenticationState = .unauthenticated
      throw error
    }
  }

  public func signUp(withEmail email: String, password: String) async throws {
    authenticationState = .authenticating

    let currentUser = Auth.auth().currentUser
    let isAnonymous = currentUser?.isAnonymous == true

    do {
      let credential = EmailAuthProvider.credential(withEmail: email, password: password)

      if isAnonymous {
        // Link the credential to anonymous user
        try await link(with: credential)
      } else {
        // Non-anonymous user - can't sign up with email/password (would be linking to existing account)
        // Instead, try to sign in with the credential
        try await signIn(withEmail: email, password: password)
      }
    }
    catch {
      authenticationState = .unauthenticated
      throw error
    }
  }
}
