//
//  SignInSecurityView.swift
//  IdentityKit
//
//  Created by Peter Friese on 09.05.26
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import SwiftUI
import os.log

struct SignInSecurityView: View {
  @Environment(AuthenticationService.self) private var authenticationService

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "SignInSecurityView")

  private var connectedProviders: [String] {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return []
    }
    return providerData.map { $0.providerID }
  }

  var body: some View {
    List {
      Section {
        ForEach(connectedProviders, id: \.self) { provider in
          HStack {
            Image(systemName: iconName(for: provider))
              .font(.title3)
              .foregroundStyle(.secondary)
              .frame(width: 32)

            Text(displayName(for: provider))
              .font(.body)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
          }
        }
      } header: {
        Text("Sign-In Methods")
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Sign-In & Security")
    .platform.navigationBarTitleDisplayMode(.inline)
  }

  private func displayName(for providerID: String) -> String {
    switch providerID {
    case "password", "email":
      return "Email / Password"
    case "google.com":
      return "Google"
    case "apple.com":
      return "Apple"
    default:
      return providerID
    }
  }

  private func iconName(for providerID: String) -> String {
    switch providerID {
    case "password", "email":
      return "envelope.fill"
    case "google.com":
      return "g.circle.fill"
    case "apple.com":
      return "apple.logo"
    default:
      return "person.fill"
    }
  }
}

#Preview {
  NavigationStack {
    SignInSecurityView()
      .environment(AuthenticationService.shared)
  }
}