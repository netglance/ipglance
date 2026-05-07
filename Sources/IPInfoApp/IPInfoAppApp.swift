// Sources/IPInfoApp/IPInfoAppApp.swift
import SwiftUI

@main
struct IPInfoAppApp: App {
    @State private var viewModel = IPViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.statusText) {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.menu)
    }
}
