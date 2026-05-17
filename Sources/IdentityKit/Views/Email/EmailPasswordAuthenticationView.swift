//
// EmailPasswordAuthenticationView.swift
// IdentityKit
//
// Created by Peter Friese on 28.01.25.
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

private enum FocusableField: Hashable {
  case email
  case password
  case confirmPassword
}

extension EnvironmentValues {
  @Entry var authenticationFlow: AuthenticationFlow = .login
}

@MainActor
struct EmailPasswordAuthenticationView {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.authenticationFlow) private var flow
  @Environment(\.dismiss) private var dismiss

  @State private var email = ""
  @State private var password = ""
  @State private var confirmPassword = ""

  @State private var errorMessage = ""

  @FocusState private var focus: FocusableField?

  private var onSuccess: (() -> Void)?
  private var onError: ((Error) -> Void)?

  init(
    onSuccess: (() -> Void)? = nil,
    onError: ((Error) -> Void)? = nil
  ) {
    self.onSuccess = onSuccess
    self.onError = onError
  }

  private var isValid: Bool {
    return if flow == .login {
      !email.isEmpty && !password.isEmpty
    } else if flow == .reauthentication {
      !password.isEmpty
    } else {
      !email.isEmpty && !password.isEmpty && password == confirmPassword
    }
  }

  private var title: String {
    switch flow {
    case .login:
      return "Log in with password"
    case .signUp:
      return "Sign up"
    case .reauthentication:
      return "Continue"
    }
  }

  private func signInWithEmailPassword() async {
    do {
      try await authenticationService.signIn(withEmail: email, password: password)
      if let onSuccess {
        onSuccess()
      } else {
        dismiss()
      }
    }
    catch {
      if let onError {
        onError(error)
      } else {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func signUpWithEmailPassword() async {
    do {
      try await authenticationService.signUp(withEmail: email, password: password)
      dismiss()
    }
    catch {
      if let onError {
        onError(error)
      } else {
        errorMessage = error.localizedDescription
      }
    }
  }
}

extension EmailPasswordAuthenticationView: View {
  var body: some View {
    VStack {
      if flow != .reauthentication {
        LabeledContent {
          TextField("Email", text: $email)
            .platform.textInputAutocapitalization(.never)
            .focused($focus, equals: .email)
            .submitLabel(.next)
            .onSubmit {
              self.focus = .password
            }
        } label: {
          Image(systemName: "at")
        }
        .padding(.vertical, 6)
        .background(Divider(), alignment: .bottom)
        .padding(.bottom, 4)
      }

      LabeledContent {
        SecureField("Password", text: $password)
          .focused($focus, equals: .password)
          .submitLabel(.go)
          .onSubmit {
            Task { await submitAction() }
          }
      } label: {
        Image(systemName: "lock")
      }
      .padding(.vertical, 6)
      .background(Divider(), alignment: .bottom)
      .padding(.bottom, 8)

      if flow == .login {
        Button("Forgot password?") {
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }

      if flow == .signUp {
        LabeledContent {
          SecureField("Confirm password", text: $confirmPassword)
            .focused($focus, equals: .confirmPassword)
            .submitLabel(.go)
            .onSubmit {
              Task { await signUpWithEmailPassword() }
            }
        } label: {
          Image(systemName: "lock")
        }
        .padding(.vertical, 6)
        .background(Divider(), alignment: .bottom)
        .padding(.bottom, 8)
      }

      Button(action: {
        Task { await submitAction() }
      }) {
        if authenticationService.authenticationState != .authenticating {
          Text(title)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        } else {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
      }
      .disabled(!isValid)
      .padding([.top, .bottom], 8)
      .frame(maxWidth: .infinity)
      .buttonStyle(.borderedProminent)
    }
    .preference(key: AuthenticationErrorMessagePreferenceKey.self, value: errorMessage)
  }

  private func submitAction() async {
    if flow == .login {
      await signInWithEmailPassword()
    } else if flow == .reauthentication {
      await signInWithEmailPassword()
    } else {
      await signUpWithEmailPassword()
    }
  }
}

#Preview {
  EmailPasswordAuthenticationView()
    .environment(AuthenticationService.shared)
}
