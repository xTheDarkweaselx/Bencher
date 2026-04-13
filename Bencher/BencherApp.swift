//
//  BencherApp.swift
//  Bencher
//
//  Created by Adam Ibrahim on 19/11/2024.
//

import SwiftUI

@main
struct BencherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1400, height: 900)
        #endif
    }
}
