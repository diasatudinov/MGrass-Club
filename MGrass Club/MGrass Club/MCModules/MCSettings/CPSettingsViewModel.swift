//
//  CPSettingsViewModel.swift
//  MGrass Club
//
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("volumeEnabled") var volumeEnabled: Bool = true

}
