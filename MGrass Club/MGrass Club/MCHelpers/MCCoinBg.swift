//
//  MCCoinBg.swift
//  MGrass Club
//
//


import SwiftUI

struct MCCoinBg: View {
    @StateObject var user = MCUser.shared
    var height: CGFloat = MCDeviceManager.shared.deviceType == .pad ? 100:50
    var body: some View {
        ZStack {
            Image(.coinsBgMC)
                .resizable()
                .scaledToFit()
            
            Text("\(user.money)")
                .font(.system(size: MCDeviceManager.shared.deviceType == .pad ? 45:25, weight: .black))
                .foregroundStyle(.black)
                .textCase(.uppercase)
                .offset(x: -25)
            
            
            
        }.frame(height: height)
        
    }
}

#Preview {
    MCCoinBg()
}
