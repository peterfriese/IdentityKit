//
//  PlatformProxy+ListStyle.swift
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

extension PlatformProxy where Content: View {
    #if os(iOS)
    public func listStyle(_ style: PlatformListStyle) -> some View {
        switch style {
        case .insetGrouped:
            return AnyView(content.listStyle(.insetGrouped))
        }
    }
    #else
    public func listStyle(_ style: PlatformListStyle) -> some View {
        return AnyView(content)
    }
    #endif
}

extension View {
    public func platformListStyle(_ style: PlatformListStyle) -> some View {
        #if os(iOS)
        switch style {
        case .insetGrouped:
            return self.listStyle(.insetGrouped)
        }
        #else
        return self
        #endif
    }
}