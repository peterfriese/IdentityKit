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
  @Environment(AuthenticationService.self) private var authService

  var userName: String {
    authService.currentUser?.displayName ?? authService.currentUser?.email ?? "(unknown)"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("👋🏻 Hello \(authService.isAuthenticated ? userName : "")!")
            Text("You are \(authService.isAuthenticated ? "" : "not") signed in")
              .foregroundStyle(.secondary)

            if authService.isAuthenticated,
               let signInTime = authService.currentUser?.metadata.lastSignInDate {
              Text("Signed in \(signInTime, style: .relative)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        Section {
          Button {
            if authService.isAuthenticated {
              do {
                try authService.signOut()
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
              authService.isAuthenticated ? "Sign Out" : "Sign In",
              systemImage: authService.isAuthenticated ? "rectangle.portrait.and.arrow.right" : "person.crop.circle.badge.plus"
            )
          }

          NavigationLink(value: AppDestination.account) {
            Label("Account Settings", systemImage: "person.crop.circle")
          }
        }

        if authService.isAuthenticated {
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
        }
      }
      .sheet(isPresented: $presentingAuthenticationDialog) {
        AuthenticationScreen()
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