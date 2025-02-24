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
  @State var presentingDeleteAccountConfirmation = false
  @State var authenticationService = AuthenticationService.shared

  var userName: String {
    authenticationService.currentUser?.displayName ?? authenticationService.currentUser?.email ?? "(unknown)"
  }

  var body: some View {
    VStack {
      Text("👋🏻 Hello \(authenticationService.isAuthenticated ? userName : "")!")
      Text("You are \(authenticationService.isAuthenticated ? "" : "not") signed in")

      Button("Sign \(authenticationService.isAuthenticated ? "out" : "in")") {
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
      }

      if authenticationService.isAuthenticated {
        Button("Delete account", role: .destructive) {
          presentingDeleteAccountConfirmation.toggle()
        }
      }
    }
    .sheet(isPresented: $presentingAuthenticationDialog) {
      AuthenticationScreen()
        .environment(authenticationService)
    }
    .sheet(isPresented: $presentingDeleteAccountConfirmation) {
      AccountDeletionConfirmationDialog {
        Task {
          await authenticationService.deleteAccount()
        }
      }
    }

  }
}

#Preview {
  ContentView()
}
