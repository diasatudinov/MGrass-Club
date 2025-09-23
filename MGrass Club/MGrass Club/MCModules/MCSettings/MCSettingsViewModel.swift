//
//  MCSettingsViewModel.swift
//  MGrass Club
//
//


import SwiftUI

class MCSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("volumeEnabled") var volumeEnabled: Bool = true

}
