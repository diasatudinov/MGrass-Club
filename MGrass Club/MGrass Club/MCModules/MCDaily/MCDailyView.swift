//
//  MCDailyView.swift
//  MGrass Club
//
//

import SwiftUI

struct MCDailyView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MCDailyRewardsViewModel()
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    private let dayCellHeight: CGFloat = MCDeviceManager.shared.deviceType == .pad ? 200:45
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                ZStack {
                    Image(.dailyViewBgMC)
                        .resizable()
                        .scaledToFit()
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(1...viewModel.totalDaysCount, id: \.self) { day in
                            ZStack {
                                
                                Image(viewModel.isDayClaimed(day) ? .receivedBgMC : .getBgMC)
                                    .resizable()
                                    .scaledToFit()
                                    .opacity(viewModel.isDayUnlocked(day) ? 1 : 0.5)
                                
                            }
                            .frame(width: 105, height: dayCellHeight)
                            .offset(x: day > 6 ? 105:0)
                            
                            
                        }
                    }.frame(width: MCDeviceManager.shared.deviceType == .pad ? 800:350, height: 250).padding(.top, 50)
                    
                    VStack{
                        
                        Spacer()
                        
                        Button {
                            viewModel.claimNext()
                        } label: {
                            Image(.getBtnMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 45)
                        }
                    }
                }.frame(height: 360)
            }
            
            VStack {
                ZStack {
                    
                    HStack(alignment: .top) {
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: MCDeviceManager.shared.deviceType == .pad ? 100:75)
                        }
                        
                        Spacer()
                                                
                    }
                }.padding([.horizontal, .top])
                Spacer()
                
            }
            
        }.background(
            ZStack {
                Image(.appBg1MC)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
        )
    }
}

#Preview {
    MCDailyView()
}
