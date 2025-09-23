//
//  MCMenuView.swift
//  MGrass Club
//
//

import SwiftUI

struct MCMenuView: View {
    @State private var showGame = false
    @State private var showShop = false
    @State private var showAchievement = false
    @State private var showMiniGames = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    
    @StateObject var shopVM = MCShopViewModel()
    
    var body: some View {
        
        ZStack {
            
            
            VStack(spacing: 0) {
                
                HStack {
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(.settingsIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:75)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showDailyReward = true
                        }
                    } label: {
                        Image(.dailyIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:75)
                    }
                }
            }.padding()
            
            ZStack {
                Image(.menuViewBgMC)
                    .resizable()
                    .scaledToFit()
                
                
                VStack {
                    Spacer()
                    
                    Button {
                        showGame = true
                    } label: {
                        Image(.playIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 140:55)
                    }
                    
                    Button {
                        showShop = true
                    } label: {
                        Image(.shopIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 140:55)
                    }
                    
                    Button {
                        showAchievement = true
                    } label: {
                        Image(.achievementsIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 140:55)
                    }
                }.padding(.bottom, 40)
            }.frame(height: 340)
            
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBg1MC)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                }
            )
            .fullScreenCover(isPresented: $showGame) {
                ForestGrowthView()
            }
            .fullScreenCover(isPresented: $showAchievement) {
                MCAchievementsView()
            }
            .fullScreenCover(isPresented: $showShop) {
                MCShopView(viewModel: shopVM)
            }
            .fullScreenCover(isPresented: $showSettings) {
                MCSettingsView()
            }
            .fullScreenCover(isPresented: $showDailyReward) {
                MCDailyView()
            }
    }
}

#Preview {
    MCMenuView()
}
