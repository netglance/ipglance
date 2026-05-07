// Sources/IPInfoApp/MenuBarView.swift
import SwiftUI
import IPInfoCore

struct MenuBarView: View {
    var viewModel: IPViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let info = viewModel.countryInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.flagEmoji)
                        .font(.system(size: 36))
                    Text(info.countryName)
                        .font(.headline)
                    Text(info.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                Divider()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                Divider()
            }

            Button("Обновить") {
                Task { await viewModel.refresh() }
            }
            .keyboardShortcut("r")
            .disabled(viewModel.isLoading)

            Divider()

            Button("Выйти") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .frame(minWidth: 200)
    }
}
