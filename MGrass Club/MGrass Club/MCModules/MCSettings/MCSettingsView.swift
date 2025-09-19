//
//  MCSettingsView.swift
//  MGrass Club
//
//

import SwiftUI

struct MCSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
        @StateObject var settingsVM = CPSettingsViewModel()
        var body: some View {
            ZStack {
                
                VStack {
                    
                    ZStack {
                        
                        Image(.settingsBgMC)
                            .resizable()
                            .scaledToFit()
                        
                        
                        VStack {
                            Spacer()
                            VStack(spacing: 30) {
                                HStack {
                                    Image(.musicTextMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                                    
                                    Spacer()
                                    
                                    Button {
                                        withAnimation {
                                            settingsVM.soundEnabled.toggle()
                                        }
                                    } label: {
                                        Image(settingsVM.soundEnabled ? .onMC:.offMC)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:45)
                                    }
                                }
                                
                                HStack {
                                    Image(.volumeTextMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                                    
                                    Spacer()
                                    
                                    Button {
                                        withAnimation {
                                            settingsVM.volumeEnabled.toggle()
                                        }
                                    } label: {
                                        ZStack {
                                            Image(.btnBgMC)
                                                .resizable()
                                                .scaledToFit()
                                            
                                            Text(settingsVM.volumeEnabled ? "100%" : "0%")
                                                .foregroundStyle(.black)
                                                .bold()
                                            
                                                
                                        }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:45)
                                    }
                                }
                                
                                HStack {
                                    Image(.languageTextMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:25)
                                    
                                    Spacer()
                                    
                                    
                                    Image(.englishBtnMC)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:45)
                                    
                                }
                            }
                            
                          
                                
                            
                        }.frame(width: 300).padding(.bottom, 20)
                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:313)
                    
                }
                
                VStack {
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMC)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:75)
                        }
                        
                        Spacer()
                        
                    }.padding()
                    Spacer()
                    
                }
            }.frame(maxWidth: .infinity)
                .background(
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
    MCSettingsView()
}
