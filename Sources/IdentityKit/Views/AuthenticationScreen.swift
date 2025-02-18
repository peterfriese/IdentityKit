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

import SwiftUI
import _AuthenticationServices_SwiftUI

// See https://medium.com/@mhd.nidal.mhd/view-validation-in-swiftui-ba02d2b59f5a for a full-blown validation solution
struct AuthenticationErrorMessagePreferenceKey: PreferenceKey {
  static let defaultValue: String? = nil

  static func reduce(value: inout String?, nextValue: () -> String?) {
    value = value ?? nextValue()
  }
}

enum AuthenticationFlow {
  case login
  case signUp
}

public struct AuthenticationScreen {
  // MARK: - Dependencies
  @Environment(AuthenticationService.self) private var authenticationService

  // MARK: - Private properties
  @State private var flow: AuthenticationFlow = .login

  private func switchFlow() {
    flow = flow == .login ? .signUp : .login
    errorMessage = ""
  }

  @State private var errorMessage = ""

  public init() {
  }
}

extension AuthenticationScreen: View {
  public var body: some View {
    VStack {
      ZStack {
        Text("Login")
          .font(.largeTitle)
          .fontWeight(.bold)
          .frame(maxWidth: .infinity, alignment: .leading)
          .opacity(flow == .login ? 1 : 0)
        Text("Sign up")
          .font(.largeTitle)
          .fontWeight(.bold)
          .frame(maxWidth: .infinity, alignment: .leading)
          .opacity(flow == .signUp ? 1 : 0)
      }

      EmailPasswordAuthenticationView()
        .environment(\.authenticationFlow, flow)

      if !errorMessage.isEmpty {
        VStack {
          Text(errorMessage)
            .foregroundColor(Color(UIColor.systemRed))
        }
      }

      HStack {
        VStack { Divider() }
        Text("or")
        VStack { Divider() }
      }

//      HStack(spacing: 16) {
//        AuthenticateWithAppleButton()
//        AuthenticateWithGoogleButton()
//      }
//      .frame(maxWidth: .infinity)

      VStack(spacing: 16) {
        AuthenticateWithAppleButton(flow == .login ? .signIn : .signUp)
        AuthenticateWithGoogleButton(flow == .login ? .signIn : .signUp)
      }

      HStack {
        Text(flow == .login ? "Don't have an account yet?" : "Already have an account?")
        Button(action: {
          withAnimation {
            switchFlow()
          }
        }) {
          Text(flow == .signUp ? "Log in" : "Sign up")
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
      }
      .padding([.top, .bottom], 50)

    }
    .padding()
    .frame(maxHeight: .infinity, alignment: .bottom)
    .onPreferenceChange(AuthenticationErrorMessagePreferenceKey.self) { [errorBinding = $errorMessage] value in
      errorBinding.wrappedValue = value ?? ""
      print(value ?? "???")
    }
  }
}

#Preview {
  AuthenticationScreen()
    .environment(AuthenticationService.shared)
}
