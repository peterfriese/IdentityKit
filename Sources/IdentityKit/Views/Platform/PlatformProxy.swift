//
//  PlatformProxy.swift
//  IdentityKit
//
//  Created by Peter Friese on 03.05.26
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

/// A wrapper for platform-specific SwiftUI view extensions.
///
/// This type provides a fluent interface for applying platform-specific styling
/// and behavior to views in a cross-platform manner.
///
/// ## Topics
/// ### Initializers
///
/// ### Properties
/// - ``content``
public struct PlatformProxy<Content> {
    public let content: Content

    init(_ content: Content) {
        self.content = content
    }
}

extension View {
    public var platform: PlatformProxy<Self> {
        PlatformProxy(self)
    }
}

/// Platform-specific title display modes for navigation views.
///
/// This enum provides cross-platform support for title display behavior.
public enum PlatformTitleDisplayMode: Sendable {
    case automatic
    case inline
    case large
}

/// Platform-specific text input autocapitalization behavior.
///
/// This enum provides cross-platform support for controlling text input
/// capitalization behavior.
public enum PlatformTextInputAutocapitalization: Sendable {
  case never
  case sentences
  case words
  case allCharacters
}

/// Platform-specific list styles.
///
/// This enum provides cross-platform support for list styling.
public enum PlatformListStyle: Sendable {
    case insetGrouped
}