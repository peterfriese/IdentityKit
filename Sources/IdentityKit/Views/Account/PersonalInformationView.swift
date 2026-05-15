//
//  PersonalInformationView.swift
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
//

import SwiftUI
import NukeUI

struct PersonalInformationView: View {
  @Environment(AuthenticationService.self) private var authenticationService

  @State private var showingAvatarEdit = false
  @State private var showingNameEdit = false
  @State private var showingEmailEdit = false
  @State private var showingPasswordEdit = false

  var body: some View {
    let _ = authenticationService.currentUser

    List {
      Section {
        VStack(spacing: 16) {
          avatarImage
            .frame(width: 100, height: 100)
            .clipShape(Circle())

          Button("Change Photo") {
            showingAvatarEdit = true
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      }
      .listRowBackground(Color.clear)

      Section {
        Button {
          showingNameEdit = true
        } label: {
          HStack {
            Text("Name")
              .foregroundStyle(.primary)
            Spacer()
            Text(authenticationService.currentUser?.displayName ?? "Not set")
              .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
        }

        Button {
          showingEmailEdit = true
        } label: {
          HStack {
            Text("Email")
              .foregroundStyle(.primary)
            Spacer()
            Text(authenticationService.currentUser?.email ?? "Not set")
              .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
        }

        Button {
          showingPasswordEdit = true
        } label: {
          HStack {
            Text("Password")
              .foregroundStyle(.primary)
            Spacer()
            if !hasPasswordProvider {
              Text(passwordRowSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
        }
      }
    }
    .platform.listStyle(.insetGrouped)
    .navigationTitle("Personal Information")
    .platform.navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingAvatarEdit) {
      NavigationStack {
        AvatarEditView()
          .environment(authenticationService)
      }
    }
    .sheet(isPresented: $showingNameEdit) {
      NavigationStack {
        NameEditView()
          .environment(authenticationService)
      }
    }
    .sheet(isPresented: $showingEmailEdit) {
      NavigationStack {
        EmailEditView()
          .environment(authenticationService)
      }
    }
    .sheet(isPresented: $showingPasswordEdit) {
      NavigationStack {
        PasswordEditView(mode: hasPasswordProvider ? .changePassword : .setPassword)
          .environment(authenticationService)
      }
    }
  }

  @ViewBuilder
  private var avatarImage: some View {
    if let photoURL = authenticationService.currentUser?.photoURL {
      LazyImage(url: photoURL) { state in
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else if state.error != nil {
          placeholderAvatar
        } else {
          placeholderAvatar
        }
      }
    } else {
      placeholderAvatar
    }
  }

  private var placeholderAvatar: some View {
    Image(systemName: "person.fill")
      .font(.system(size: 40))
      .foregroundStyle(.secondary)
      .frame(width: 100, height: 100)
      .background(Color.gray.opacity(0.2))
  }

  private var hasPasswordProvider: Bool {
    guard let providerData = authenticationService.currentUser?.providerData else {
      return false
    }
    return providerData.contains { $0.providerID == "password" || $0.providerID == "email" }
  }

  private var passwordRowSubtitle: String {
    hasPasswordProvider ? "" : "Add a password to your account"
  }
}

#Preview {
  NavigationStack {
    PersonalInformationView()
      .environment(AuthenticationService.shared)
  }
}