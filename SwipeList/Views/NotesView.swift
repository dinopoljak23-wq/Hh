import SwiftUI

struct NotesView: View {
    @EnvironmentObject var store: NotesStore
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var selectedNote: Note?

    var filteredNotes: [Note] {
        let sorted = store.sortedNotes
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Search
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                if store.notes.isEmpty {
                    emptyState
                } else {
                    // Notes Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredNotes) { note in
                                NoteCard(note: note, onTap: {
                                    selectedNote = note
                                }, onDelete: {
                                    store.deleteNote(note)
                                }, onPin: {
                                    store.togglePin(note)
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                        .padding(.trailing, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddNoteSheet()
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(item: $selectedNote) { note in
            EditNoteSheet(note: note)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notizen")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B8B8D0")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("\(store.notes.count) \(store.notes.count == 1 ? "Notiz" : "Notizen")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8B8BA0"))
            }

            Spacer()
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "6C6C80"))
                .font(.system(size: 16))

            TextField("Notizen durchsuchen...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tint(Color(hex: "A855F7"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A2E").opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "A855F7").opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "note.text")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "A855F7").opacity(0.5))
            }

            Text("Noch keine Notizen")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "8B8BA0"))

            Text("Tippe auf + um eine Notiz zu erstellen")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C6C80"))

            Spacer()
        }
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "A855F7"), Color(hex: "6C5CE7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(hex: "A855F7").opacity(0.5), radius: 16, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Note Card
struct NoteCard: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Pin indicator & menu
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .rotationEffect(.degrees(45))
                    }

                    Spacer()

                    Menu {
                        Button {
                            onPin()
                        } label: {
                            Label(
                                note.isPinned ? "Lösen" : "Anheften",
                                systemImage: note.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 28, height: 28)
                    }
                }

                // Title
                Text(note.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Content Preview
                Text(note.content)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Date
                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: note.color.gradient.map { $0.opacity(0.6) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Add Note Sheet
struct AddNoteSheet: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedColor: NoteColor = .purple
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A1A").ignoresSafeArea()

                VStack(spacing: 20) {
                    // Color Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(NoteColor.allCases) { color in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedColor = color
                                    }
                                } label: {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: color.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if selectedColor == color {
                                                Circle()
                                                    .stroke(.white, lineWidth: 3)
                                                    .padding(2)
                                            }
                                        }
                                }
                            }
                        }
                    }

                    // Title
                    TextField("Titel...", text: $title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .tint(Color(hex: "A855F7"))
                        .focused($isTitleFocused)

                    // Content
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Notiz schreiben...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6C6C80"))
                                .padding(.top, 8)
                        }

                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .tint(Color(hex: "A855F7"))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                    }

                    Spacer()

                    // Save Button
                    Button {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let note = Note(
                            title: title.trimmingCharacters(in: .whitespaces),
                            content: content.trimmingCharacters(in: .whitespaces),
                            color: selectedColor
                        )
                        store.addNote(note)
                        dismiss()
                    } label: {
                        Text("Speichern")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: title.isEmpty
                                                ? [Color(hex: "2A2A3E"), Color(hex: "2A2A3E")]
                                                : selectedColor.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Neue Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Color(hex: "A855F7"))
                }
            }
            .onAppear { isTitleFocused = true }
        }
    }
}

// MARK: - Edit Note Sheet
struct EditNoteSheet: View {
    @EnvironmentObject var store: NotesStore
    @Environment(\.dismiss) var dismiss
    let note: Note
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedColor: NoteColor = .purple

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A1A").ignoresSafeArea()

                VStack(spacing: 20) {
                    // Color Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(NoteColor.allCases) { color in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedColor = color
                                    }
                                } label: {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: color.gradient,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if selectedColor == color {
                                                Circle()
                                                    .stroke(.white, lineWidth: 3)
                                                    .padding(2)
                                            }
                                        }
                                }
                            }
                        }
                    }

                    // Title
                    TextField("Titel...", text: $title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .tint(Color(hex: "A855F7"))

                    // Content
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Notiz schreiben...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6C6C80"))
                                .padding(.top, 8)
                        }

                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .tint(Color(hex: "A855F7"))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                    }

                    Spacer()

                    // Save Button
                    Button {
                        var updated = note
                        updated.title = title.trimmingCharacters(in: .whitespaces)
                        updated.content = content.trimmingCharacters(in: .whitespaces)
                        updated.color = selectedColor
                        store.updateNote(updated)
                        dismiss()
                    } label: {
                        Text("Aktualisieren")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: selectedColor.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Notiz bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(Color(hex: "A855F7"))
                }
            }
            .onAppear {
                title = note.title
                content = note.content
                selectedColor = note.color
            }
        }
    }
}
