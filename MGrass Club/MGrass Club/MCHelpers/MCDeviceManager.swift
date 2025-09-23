//
//  MCDeviceManager.swift
//  MGrass Club
//
//



import UIKit

class MCDeviceManager {
    static let shared = MCDeviceManager()
    
    var deviceType: UIUserInterfaceIdiom
    
    private init() {
        self.deviceType = UIDevice.current.userInterfaceIdiom
    }
}
