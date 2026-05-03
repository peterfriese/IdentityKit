//
//  PlatformProxy+Background.swift
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

extension PlatformProxy where Content: View {
    @ViewBuilder
    public func secondaryBackground() -> some View {
        #if os(iOS)
        content.background(Color(.secondarySystemBackground))
        #else
        content.background(Color.gray.opacity(0.2))
        #endif
    }

    @ViewBuilder
    public func secondaryBackground<S: Shape>(_ shape: S) -> some View {
        #if os(iOS)
        content.background(Color(.secondarySystemBackground), in: shape)
        #else
        content.background(Color.gray.opacity(0.2), in: shape)
        #endif
    }
}

extension Color {
    public static var platformSecondaryBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #else
        Color.gray.opacity(0.2)
        #endif
    }
}