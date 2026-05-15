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
//

import SwiftUI

struct AuthenticateWithAppleButton: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) var dismiss

  @State private var isAuthenticating = false

  private var mode: AuthenticationMode
  private var onSuccess: (() -> Void)?
  private var onFailure: ((Error) -> Void)?

  init(
    _ mode: AuthenticationMode = .continue,
    onSuccess: (() -> Void)? = nil,
    onFailure: ((Error) -> Void)? = nil
  ) {
    self.mode = mode
    self.onSuccess = onSuccess
    self.onFailure = onFailure
  }

  var body: some View {
    Button {
      isAuthenticating = true
    } label: {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 8) {
          Image(systemName: "apple.logo")
            .font(.title)
            .frame(width: 32, height: 32)

          Text("\(mode) with Apple")
            .font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)

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
      defer { isAuthenticating = false }

      do {
        try await authenticationService.signInWithApple()
        if let onSuccess {
          onSuccess()
        } else {
          dismiss()
        }
      }
      catch {
        if let onFailure {
          onFailure(error)
        } else {
          authenticationService.errorMessage = error.localizedDescription
        }
      }
    }
  }
}