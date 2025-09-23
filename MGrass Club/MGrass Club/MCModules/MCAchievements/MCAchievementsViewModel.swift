//
//  MCAchievementsViewModel.swift
//  MGrass Club
//
//


import SwiftUI

class MCAchievementsViewModel: ObservableObject {
    
    @Published var achievements: [NEGAchievement] = [
        NEGAchievement(image: "achieve1ImageMC", title: "achieve1TextMC", isAchieved: false),
        NEGAchievement(image: "achieve2ImageMC", title: "achieve2TextMC", isAchieved: false),
        NEGAchievement(image: "achieve3ImageMC", title: "achieve3TextMC", isAchieved: false),
        NEGAchievement(image: "achieve4ImageMC", title: "achieve4TextMC", isAchieved: false),
        NEGAchievement(image: "achieve5ImageMC", title: "achieve5TextMC", isAchieved: false),
    ] {
        didSet {
            saveAchievementsItem()
        }
    }
        
    init() {
        loadAchievementsItem()
        
    }
    
    private let userDefaultsAchievementsKey = "achievementsKeyHKH"
    
    func achieveToggle(_ achive: NEGAchievement) {
        guard let index = achievements.firstIndex(where: { $0.id == achive.id })
        else {
            return
        }
        achievements[index].isAchieved.toggle()
        
    }
   
    
    
    func saveAchievementsItem() {
        if let encodedData = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsAchievementsKey)
        }
        
    }
    
    func loadAchievementsItem() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsAchievementsKey),
           let loadedItem = try? JSONDecoder().decode([NEGAchievement].self, from: savedData) {
            achievements = loadedItem
        } else {
            print("No saved data found")
        }
    }
}

struct NEGAchievement: Codable, Hashable, Identifiable {
    var id = UUID()
    var image: String
    var title: String
    var isAchieved: Bool
}
