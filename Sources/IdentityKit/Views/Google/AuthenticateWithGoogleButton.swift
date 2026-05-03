//
// AuthenticateWithGoogleButton.swift
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

struct AuthenticateWithGoogleButton: View {
  // MARK: - Dependencies
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) var dismiss

  // MARK: - State
  @State private var isAuthenticating = false
  @State private var errorMessage: String?

  private var mode: AuthenticationMode

  init(_ mode: AuthenticationMode = .continue) {
    self.mode = mode
  }

  private var googleLogo: Image {
    #if os(iOS)
    Image("google.logo", bundle: .module)
    #else
    Image("google.logo")
    #endif
  }

  var body: some View {
    Button {
      isAuthenticating = true
    } label: {
      ViewThatFits(in: .horizontal) {
        // First attempt: show both logo and text
        HStack(spacing: 8) {
          googleLogo
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)

          Text("\(mode) with Google")
            .font(.body.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)

        // Fallback: show only the logo

        googleLogo
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)
          .frame(maxWidth: .infinity)
      }
      .frame(height: 32)
    }
    .buttonStyle(SocialAuthenticationButtonStyle())
    .disabled(isAuthenticating)
    .alert("Sign In Failed", isPresented: .init(
      get: { errorMessage != nil },
      set: { if !$0 { errorMessage = nil } }
    )) {
      Button("OK", role: .cancel) { }
    } message: {
      if let errorMessage {
        Text(errorMessage)
      }
    }
    .task(id: isAuthenticating) {
      guard isAuthenticating else { return }
      defer { isAuthenticating = false }

      do {
        let success = try await authenticationService.signInWithGoogle()
        if success {
          dismiss()
        }
      } catch let error as AuthenticationError {
        errorMessage = error.localizedDescription
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }
}

#Preview {
  AuthenticateWithGoogleButton()
}
