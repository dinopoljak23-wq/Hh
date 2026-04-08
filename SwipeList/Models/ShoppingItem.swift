import Foundation
import SwiftUI

enum ShoppingCategory: String, CaseIterable, Codable, Identifiable {
    case fruits = "Obst & Gemüse"
    case dairy = "Milchprodukte"
    case meat = "Fleisch & Fisch"
    case drinks = "Getränke"
    case snacks = "Snacks"
    case household = "Haushalt"
    case other = "Sonstiges"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fruits: return "leaf.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .meat: return "fish.fill"
        case .drinks: return "waterbottle.fill"
        case .snacks: return "birthday.cake.fill"
        case .household: return "house.fill"
        case .other: return "bag.fill"
        }
    }

    var color: Color {
        switch self {
        case .fruits: return Color(hex: "00B894")
        case .dairy: return Color(hex: "FDCB6E")
        case .meat: return Color(hex: "E17055")
        case .drinks: return Color(hex: "0984E3")
        case .snacks: return Color(hex: "E84393")
        case .household: return Color(hex: "6C5CE7")
        case .other: return Color(hex: "636E72")
        }
    }
}

struct ShoppingItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ShoppingCategory
    var isChecked: Bool
    var quantity: Int
    var createdAt: Date

    init(name: String, category: ShoppingCategory, quantity: Int = 1) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isChecked = false
        self.quantity = quantity
        self.createdAt = Date()
    }
}

class ShoppingStore: ObservableObject {
    @Published var items: [ShoppingItem] = [] {
        didSet { save() }
    }

    private let saveKey = "ShoppingItems"

    init() {
        load()
        if items.isEmpty {
            // Demo-Daten
            items = [
                ShoppingItem(name: "Äpfel", category: .fruits, quantity: 6),
                ShoppingItem(name: "Bananen", category: .fruits, quantity: 3),
                ShoppingItem(name: "Vollmilch", category: .dairy, quantity: 2),
                ShoppingItem(name: "Butter", category: .dairy),
                ShoppingItem(name: "Hähnchenbrust", category: .meat),
                ShoppingItem(name: "Mineralwasser", category: .drinks, quantity: 2),
                ShoppingItem(name: "Cola Zero", category: .drinks),
                ShoppingItem(name: "Chips", category: .snacks),
            ]
        }
    }

    func addItem(_ item: ShoppingItem) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            items.insert(item, at: 0)
        }
    }

    func toggleItem(_ item: ShoppingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                items[index].isChecked.toggle()
            }
        }
    }

    func deleteItem(_ item: ShoppingItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            items.removeAll { $0.id == item.id }
        }
    }

    func clearChecked() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            items.removeAll { $0.isChecked }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = decoded
        }
    }
}
