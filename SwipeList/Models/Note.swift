import Foundation
import SwiftUI

enum NoteColor: String, CaseIterable, Codable, Identifiable {
    case purple, blue, green, orange, pink, yellow

    var id: String { rawValue }

    var gradient: [Color] {
        switch self {
        case .purple: return [Color(hex: "6C5CE7"), Color(hex: "A855F7")]
        case .blue: return [Color(hex: "0984E3"), Color(hex: "74B9FF")]
        case .green: return [Color(hex: "00B894"), Color(hex: "55EFC4")]
        case .orange: return [Color(hex: "E17055"), Color(hex: "FAB1A0")]
        case .pink: return [Color(hex: "E84393"), Color(hex: "FD79A8")]
        case .yellow: return [Color(hex: "FDCB6E"), Color(hex: "FFEAA7")]
        }
    }
}

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var color: NoteColor
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    init(title: String, content: String, color: NoteColor = .purple) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.color = color
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

class NotesStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet { save() }
    }

    private let saveKey = "Notes"

    init() {
        load()
        if notes.isEmpty {
            // Demo-Daten
            var welcomeNote = Note(
                title: "Willkommen! 👋",
                content: "Das ist deine neue Notizen-App. Tippe auf + um eine neue Notiz zu erstellen.",
                color: .purple
            )
            welcomeNote.isPinned = true

            notes = [
                welcomeNote,
                Note(
                    title: "Rezept: Pasta",
                    content: "Spaghetti kochen, Knoblauch anbraten, Tomatensoße dazu, Parmesan drüber. Fertig!",
                    color: .orange
                ),
                Note(
                    title: "Fitness Ziele",
                    content: "Mo: Brust & Trizeps\nDi: Rücken & Bizeps\nMi: Pause\nDo: Beine\nFr: Schultern",
                    color: .green
                ),
                Note(
                    title: "Geburtstage",
                    content: "Mama: 15. März\nPapa: 22. Juli\nLisa: 3. September",
                    color: .pink
                ),
            ]
        }
    }

    func addNote(_ note: Note) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            notes.insert(note, at: 0)
        }
    }

    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updatedAt = Date()
            notes[index] = updated
        }
    }

    func deleteNote(_ note: Note) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            notes.removeAll { $0.id == note.id }
        }
    }

    func togglePin(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                notes[index].isPinned.toggle()
            }
        }
    }

    var sortedNotes: [Note] {
        notes.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.updatedAt > b.updatedAt
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}
