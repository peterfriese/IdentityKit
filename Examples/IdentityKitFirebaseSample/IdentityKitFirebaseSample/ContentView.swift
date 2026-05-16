//
// ContentView.swift
// IdentityKitFirebaseSample
//
// Created by Peter Friese on 30.01.25.
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
import IdentityKit

struct ContentView: View {
  @State var presentingAuthenticationDialog = false
  @State var presentingAccount = false
  @State var authenticationService = AuthenticationService.shared
  @State var accountService: AccountService = .shared

  var userName: String {
    authenticationService.currentUser?.displayName ?? authenticationService.currentUser?.email ?? "(unknown)"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("👋🏻 Hello \(authenticationService.isAuthenticated ? userName : "Guest")!")
              .font(.headline)
            Text("You are \(authenticationService.isAuthenticated ? "" : "not") signed in")
              .foregroundStyle(.secondary)
          }
        }

        Section {
          Button {
            print("[ContentView] Account button tapped")
            presentingAccount = true
          } label: {
            Label("Account", systemImage: "person.circle")
          }
        }

        Section {
          Button("Sign \(authenticationService.isAuthenticated ? "out" : "in")") {
            if authenticationService.isAuthenticated {
              print("[ContentView] Sign out button tapped")
              do {
                try authenticationService.signOut()
              }
              catch {
                print(error.localizedDescription)
              }
            }
            else {
              print("[ContentView] Sign in button tapped")
              presentingAuthenticationDialog.toggle()
            }
          }
        }
      }
      .navigationTitle("IdentityKit")
      .sheet(isPresented: $presentingAuthenticationDialog) {
        AuthenticationScreen()
          .environment(authenticationService)
          .authenticationProviders([
            .email,
            .apple,
            .google
          ])
      }
      .sheet(isPresented: $presentingAccount) {
        AccountView { error in
          print("Upgrade failed: \(error.localizedDescription)")
        }
        .environment(authenticationService)
      }
    }
  }
}

#Preview {
  ContentView()
}
