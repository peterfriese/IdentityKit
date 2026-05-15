//
// AuthenticationScreen.swift
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
//

import SwiftUI
import _AuthenticationServices_SwiftUI

struct AuthenticationErrorMessagePreferenceKey: PreferenceKey {
  static let defaultValue: String? = nil

  static func reduce(value: inout String?, nextValue: () -> String?) {
    value = value ?? nextValue()
  }
}

public enum AuthenticationFlow: Sendable {
  case login
  case signUp
  case reauthentication
}

@MainActor
public struct AuthenticationScreen {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.authenticationProviders) private var authenticationProviders
  @Environment(\.dismiss) private var dismiss

  @State private var flow: AuthenticationFlow
  @State private var errorMessage: String = ""
  private var onReauthenticate: ((ReauthenticationResult) -> Void)?

  public init(
    flow: AuthenticationFlow = .login,
    onReauthenticate: ((ReauthenticationResult) -> Void)? = nil
  ) {
    self._flow = State(initialValue: flow)
    self.onReauthenticate = onReauthenticate
  }

  private var title: String {
    switch flow {
    case .login: return "Login"
    case .signUp: return "Sign up"
    case .reauthentication: return "Verify Identity"
    }
  }

  private func handleReauthenticationSuccess() {
    onReauthenticate?(.success)
    dismiss()
  }

  private func handleReauthenticationFailure(_ error: Error) {
    onReauthenticate?(.failure(error))
  }

  private func switchFlow() {
    flow = flow == .login ? .signUp : .login
    errorMessage = ""
  }
}

extension AuthenticationScreen: View {
  public var body: some View {
    contentView
      .padding()
      .frame(maxHeight: .infinity, alignment: .bottom)
      .onPreferenceChange(AuthenticationErrorMessagePreferenceKey.self) { [errorBinding = $errorMessage] value in
        errorBinding.wrappedValue = value ?? ""
      }
  }

  @ViewBuilder
  private var contentView: some View {
    if flow == .reauthentication {
      reauthenticationContent
    } else {
      authContent
    }
  }

  private var reauthenticationContent: some View {
    ReauthenticationScreenContent(
      errorMessage: $errorMessage,
      onSuccess: handleReauthenticationSuccess,
      onFailure: handleReauthenticationFailure
    )
  }

  private var authContent: some View {
    AuthScreenContent(
      flow: flow,
      errorMessage: $errorMessage,
      onSwitchFlow: switchFlow
    )
  }
}

@MainActor
private struct ReauthenticationScreenContent: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.authenticationProviders) private var authenticationProviders
  @Binding var errorMessage: String
  private var onSuccess: () -> Void
  private var onFailure: (Error) -> Void

  init(
    errorMessage: Binding<String>,
    onSuccess: @escaping () -> Void,
    onFailure: @escaping (Error) -> Void
  ) {
    self._errorMessage = errorMessage
    self.onSuccess = onSuccess
    self.onFailure = onFailure
  }

  private var linkedProviderIDs: [String] {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return []
    }
    return providerData.map { $0.providerID }
  }

  private var hasPassword: Bool {
    linkedProviderIDs.contains("password") || linkedProviderIDs.contains("email")
  }

  private var hasApple: Bool {
    linkedProviderIDs.contains("apple.com")
  }

  private var hasGoogle: Bool {
    linkedProviderIDs.contains("google.com")
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Verify Identity")
          .font(.largeTitle)
          .fontWeight(.bold)

        if !linkedProviderIDs.isEmpty {
          Text("Select a method to verify your identity")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if hasPassword && authenticationProviders.contains(.email) {
          EmailPasswordAuthenticationView(
            onSuccess: onSuccess,
            onError: onFailure
          )
          .environment(\.authenticationFlow, .reauthentication)
        }

        if !errorMessage.isEmpty {
          Text(errorMessage)
            .foregroundStyle(.red)
        }

        if (hasPassword && authenticationProviders.contains(.email)) && (hasApple || hasGoogle) {
          HStack {
            VStack { Divider() }
            Text("or")
            VStack { Divider() }
          }
        }

        if hasApple && authenticationProviders.contains(.apple) {
          AuthenticateWithAppleButton(.signIn, onSuccess: onSuccess, onFailure: onFailure)
        }
        if hasGoogle && authenticationProviders.contains(.google) {
          AuthenticateWithGoogleButton(.signIn, onSuccess: onSuccess, onFailure: onFailure)
        }
      }
    }
  }
}

@MainActor
private struct AuthScreenContent: View {
  @Environment(\.authenticationProviders) private var authenticationProviders
  @Binding var errorMessage: String
  @State private var flow: AuthenticationFlow
  private var onSwitchFlow: () -> Void

  init(
    flow: AuthenticationFlow,
    errorMessage: Binding<String>,
    onSwitchFlow: @escaping () -> Void
  ) {
    self._flow = State(initialValue: flow)
    self._errorMessage = errorMessage
    self.onSwitchFlow = onSwitchFlow
  }

  private var title: String {
    switch flow {
    case .login: return "Login"
    case .signUp: return "Sign up"
    case .reauthentication: return "Verify Identity"
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(title)
          .font(.largeTitle)
          .fontWeight(.bold)

        if authenticationProviders.contains(.email) {
          EmailPasswordAuthenticationView()
            .environment(\.authenticationFlow, flow)
        }

        if !errorMessage.isEmpty {
          Text(errorMessage)
            .foregroundStyle(.red)
        }

        if authenticationProviders.contains(.email) && (authenticationProviders.contains(.apple) || authenticationProviders.contains(.google)) {
          HStack {
            VStack { Divider() }
            Text("or")
            VStack { Divider() }
          }
        }

        if authenticationProviders.contains(.apple) {
          AuthenticateWithAppleButton(flow == .login ? .signIn : .signUp)
        }
        if authenticationProviders.contains(.google) {
          AuthenticateWithGoogleButton(flow == .login ? .signIn : .signUp)
        }

        HStack {
          Text(flow == .login ? "Don't have an account yet?" : "Already have an account?")
          Button(action: {
            withAnimation {
              onSwitchFlow()
            }
          }) {
            Text(flow == .signUp ? "Log in" : "Sign up")
              .fontWeight(.semibold)
          }
        }
        .padding(.top, 50)
      }
    }
  }
}

#Preview("Login") {
  AuthenticationScreen()
    .environment(AuthenticationService.shared)
}

#Preview("Reauthentication") {
  AuthenticationScreen(flow: .reauthentication) { result in
    print("Reauth result: \(result)")
  }
  .environment(AuthenticationService.shared)
}