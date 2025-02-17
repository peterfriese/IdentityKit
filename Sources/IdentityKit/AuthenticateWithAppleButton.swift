//
// AuthenticateWithAppleButton.swift
// IdentityKit
//
// Created by Peter Friese on 17.02.25.
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

import SwiftUI

struct AuthenticateWithAppleButton: View {
  // MARK: - Dependencies
  @Environment(AuthenticationService.self) private var authenticationService

  // MARK: - State
  @State private var isAuthenticating = false

  private var mode: AuthenticationMode

  init(_ mode: AuthenticationMode = .continue) {
    self.mode = mode
  }

  var body: some View {
    Button {
      isAuthenticating = true
    } label: {
      ViewThatFits(in: .horizontal) {
        // First attempt: show both logo and text
        HStack(spacing: 8) {
          Image(systemName: "apple.logo")
            .font(.title)
            .frame(width: 32, height: 32)

          Text("\(mode) Apple")
            .font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)

        // Fallback: show only the logo
        Image(systemName: "apple.logo")
          .font(.title)
          .frame(width: 32, height: 32)
          .frame(maxWidth: .infinity)
      }
      .frame(height: 32)
    }
    .buttonStyle(SocialAuthenticationButtonStyle())
    .disabled(isAuthenticating)
    .task(id: isAuthenticating) {
      guard isAuthenticating else { return }
      await authenticationService.signInWithApple()
      isAuthenticating = false
    }
  }
}
