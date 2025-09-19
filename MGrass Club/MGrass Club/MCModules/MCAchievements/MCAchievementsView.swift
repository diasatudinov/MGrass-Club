//
//  MCAchievementsView.swift
//  MGrass Club
//
//

import SwiftUI

struct MCAchievementsView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel = ZZAchievementsViewModel()
    @State private var index = 0
    var body: some View {
        ZStack {
            
            VStack {
                ZStack {
                    
                    HStack(alignment: .top) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                    }
                }.padding([.top])
                
                Spacer()
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.achievements, id: \.self) { item in
                            ZStack {
                                Image(item.isAchieved ? .openedAchiMC : .closedAchiMC)
                                    .resizable()
                                    .scaledToFit()
                                
                                Image(item.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:180)
                                    .opacity(item.isAchieved ? 1:0)
                                    
                                
                                VStack {
                                    Spacer()
                                    Button {
                                        viewModel.achieveToggle(item)
                                        if !item.isAchieved {
                                            user.updateUserMoney(for: 10)
                                        }
                                    } label: {
                                        Image(.getBtnMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:45)
                                    }
                                }
                            }.frame(width: 300, height: ZZDeviceManager.shared.deviceType == .pad ? 100:300)
                        }
                        
                    }
                }
                Spacer()
            }
        }
        .background(
            ZStack {
                Image(.appBg2MC)
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                
                
            }
        )
    }
}

#Preview {
    MCAchievementsView()
}
