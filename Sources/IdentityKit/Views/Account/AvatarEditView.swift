//
//  AvatarEditView.swift
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
import PhotosUI
import os.log
import FirebaseAuth
import NukeUI

struct AvatarEditView: View {
  @Environment(AuthenticationService.self) private var authenticationService
  @Environment(\.dismiss) private var dismiss

  private let logger = Logger(subsystem: "dev.peterfriese.identitykit", category: "AvatarEditView")

  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImageData: Data?
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  private var userPhotoURL: URL? {
    authenticationService.currentUser?.photoURL
  }

  private var userId: String? {
    authenticationService.currentUser?.uid
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(spacing: 16) {
            avatarImage
              .frame(width: 100, height: 100)
              .clipShape(Circle())
              .frame(maxWidth: .infinity)

            if isSaving {
              ProgressView()
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)

        Section {
          PhotosPicker(selection: $selectedItem, matching: .images) {
            Label(selectedImageData != nil ? "Choose Different Photo" : "Choose from Library", systemImage: "photo.on.rectangle")
          }
          .onChange(of: selectedItem) { _, newValue in
            Task {
              await loadAndSaveImage(from: newValue)
            }
          }
          .disabled(isSaving)
        } header: {
          Text("Photo")
        } footer: {
          if let errorMessage {
            Text(errorMessage)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Change Photo")
      .platform.navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Label("Cancel", systemImage: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            dismiss()
          } label: {
            Label("Done", systemImage: "checkmark")
          }
        }
      }
    }
  }

  @ViewBuilder
  private var avatarImage: some View {
    if let imageData = selectedImageData {
      #if canImport(UIKit)
      if let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        placeholderAvatar
      }
      #else
      placeholderAvatar
      #endif
    } else if let photoURL = userPhotoURL {
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

  private func loadAndSaveImage(from item: PhotosPickerItem?) async {
    guard let item = item else { return }

    guard let userId else {
      errorMessage = "User not authenticated"
      return
    }

    isSaving = true
    errorMessage = nil

    do {
      guard let imageData = try await item.loadTransferable(type: Data.self) else {
        errorMessage = "Failed to load image"
        isSaving = false
        return
      }

      let downloadURL = try await StorageService.shared.uploadAvatar(imageData: imageData, for: userId)

      guard let user = Auth.auth().currentUser else {
        errorMessage = "User not authenticated"
        isSaving = false
        return
      }

      let changeRequest = user.createProfileChangeRequest()
      changeRequest.photoURL = downloadURL
      try await changeRequest.commitChanges()

      selectedImageData = imageData
    }
    catch let error as AuthenticationError {
      logger.error("Failed to update photo: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
    catch {
      logger.error("Failed to update photo: \(error.localizedDescription)")
      errorMessage = "Failed to update photo. Please try again."
    }

    isSaving = false
  }
}

#Preview {
  AvatarEditView()
    .environment(AuthenticationService.shared)
}