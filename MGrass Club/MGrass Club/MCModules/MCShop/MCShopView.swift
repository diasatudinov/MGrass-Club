//
//  MCShopView.swift
//  MGrass Club
//
//

import SwiftUI

struct MCShopView: View {
    @StateObject var user = MCUser.shared
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MCShopViewModel
    @State var category: JGItemCategory = .skin
    var body: some View {
        ZStack {
            
            VStack {
                HStack {
                    
                    ForEach(category == .skin ? viewModel.shopSkinItems :viewModel.shopBgItems, id: \.self) { item in
                        achievementItem(item: item, category: category == .skin ? .skin : .background)
                        
                    }
                    
                    
                }
            }
            
            VStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(.backIconMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:50)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            category = .skin
                        } label: {
                            Image(category == .skin ? .skinsTextOnMC : .skinsTextMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:45)
                        }
                        
                        Button {
                            category = .background
                        } label: {
                            Image(category == .background ? .bgTextOnMC : .bgTextMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:45)
                        }
                    }
                    
                    Spacer()
                    
                    MCCoinBg()
                    
                    
                    
                }.padding()
                Spacer()
                
                
                
            }
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBg2MC)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            )
    }
    
    @ViewBuilder func achievementItem(item: JGItem, category: JGItemCategory) -> some View {
        ZStack {
            
            Image(item.icon)
                .resizable()
                .scaledToFit()
            VStack {
                Spacer()
                Button {
                    viewModel.selectOrBuy(item, user: user, category: category)
                } label: {
                    
                    if viewModel.isPurchased(item, category: category) {
                        ZStack {
                            Image(.longBtnBgMC)
                                .resizable()
                                .scaledToFit()
                            
                            Text(viewModel.isCurrentItem(item: item, category: category) ? "USED":"USE")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                                .bold()
                            
                        }.frame(height: MCDeviceManager.shared.deviceType == .pad ? 50:42)
                        
                    } else {
                        Image(.buyBtnMC)
                            .resizable()
                            .scaledToFit()
                            .frame(height: MCDeviceManager.shared.deviceType == .pad ? 50:42)
                            .opacity(viewModel.isMoneyEnough(item: item, user: user, category: category) ? 1:0.6)
                    }
                    
                    
                }
            }.offset(y: 8)
            
        }.frame(height: MCDeviceManager.shared.deviceType == .pad ? 300:200)
        
    }
}

#Preview {
    MCShopView(viewModel: MCShopViewModel())
}
