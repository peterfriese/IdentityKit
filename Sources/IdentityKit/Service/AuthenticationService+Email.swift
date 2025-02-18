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
    do {
      try await Auth.auth().createUser(withEmail: email, password: password)
    }
    catch {
      authenticationState = .unauthenticated
      throw error
    }
  }
}
