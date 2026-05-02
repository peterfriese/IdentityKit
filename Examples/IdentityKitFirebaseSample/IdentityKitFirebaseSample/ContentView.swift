//
// ContentView.swift
// IdentityKitFirebaseSample
//
// Created by Peter Friese on 30.01.25
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

enum AppDestination: Hashable {
  case account
}

struct ContentView: View {
  @State var presentingAuthenticationDialog = false
  @State var presentingDeleteAccountConfirmation = false
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
            Text("👋🏻 Hello \(authenticationService.isAuthenticated ? userName : "")!")
            Text("You are \(authenticationService.isAuthenticated ? "" : "not") signed in")
              .foregroundStyle(.secondary)

            if authenticationService.isAuthenticated,
               let signInTime = authenticationService.currentUser?.metadata.lastSignInDate {
              Text("Signed in \(signInTime, style: .relative)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        Section {
          Button {
            if authenticationService.isAuthenticated {
              do {
                try authenticationService.signOut()
              }
              catch {
                print(error.localizedDescription)
              }
            }
            else {
              presentingAuthenticationDialog.toggle()
            }
          } label: {
            Label(
              authenticationService.isAuthenticated ? "Sign Out" : "Sign In",
              systemImage: authenticationService.isAuthenticated ? "rectangle.portrait.and.arrow.right" : "person.crop.circle.badge.plus"
            )
          }

          NavigationLink(value: AppDestination.account) {
            Label("Account Settings", systemImage: "person.crop.circle")
          }
        }

        if authenticationService.isAuthenticated {
          Section("Danger Zone") {
            Button(role: .destructive) {
              presentingDeleteAccountConfirmation.toggle()
            } label: {
              Label("Delete Account", systemImage: "trash")
            }
          }
        }
      }
      .navigationDestination(for: AppDestination.self) { destination in
        switch destination {
        case .account:
          AccountView()
            .environment(authenticationService)
        }
      }
      .sheet(isPresented: $presentingAuthenticationDialog) {
        AuthenticationScreen()
          .environment(authenticationService)
          .authenticationProviders([
            .email,
            .apple
          ])
      }
      .sheet(isPresented: $presentingDeleteAccountConfirmation) {
        AccountDeletionConfirmationDialog {
          Task {
            do {
              try await accountService.deleteAccount()
            }
            catch {
              print(error)
            }
          }
        }
      }
      .navigationTitle("IdentityKit")
    }
  }
}

#Preview {
  ContentView()
}