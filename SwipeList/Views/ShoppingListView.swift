import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var store: ShoppingStore
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var showCheckedItems = true

    var filteredItems: [ShoppingItem] {
        let items = store.items.filter { item in
            searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
        }
        return items
    }

    var uncheckedItems: [ShoppingItem] {
        filteredItems.filter { !$0.isChecked }
    }

    var checkedItems: [ShoppingItem] {
        filteredItems.filter { $0.isChecked }
    }

    var groupedUnchecked: [(ShoppingCategory, [ShoppingItem])] {
        let grouped = Dictionary(grouping: uncheckedItems, by: { $0.category })
        return ShoppingCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color.clear

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Search Bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                if store.items.isEmpty {
                    emptyState
                } else {
                    // Items List
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            // Unchecked items grouped by category
                            ForEach(groupedUnchecked, id: \.0) { category, items in
                                categorySection(category: category, items: items)
                            }

                            // Checked items
                            if !checkedItems.isEmpty {
                                checkedSection
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
            AddShoppingItemSheet()
                .environmentObject(store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Einkaufsliste")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B8B8D0")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                let count = uncheckedItems.count
                Text("\(count) \(count == 1 ? "Artikel" : "Artikel") übrig")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8B8BA0"))
            }

            Spacer()

            if !checkedItems.isEmpty {
                Button {
                    store.clearChecked()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Erledigt löschen")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "E17055"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(Color(hex: "E17055").opacity(0.15))
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "6C6C80"))
                .font(.system(size: 16))

            TextField("Suchen...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tint(Color(hex: "6C5CE7"))
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

    // MARK: - Category Section
    private func categorySection(category: ShoppingCategory, items: [ShoppingItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(category.color)

                Spacer()

                Text("\(items.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(category.color.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(category.color.opacity(0.12))
                    }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)

            // Items
            ForEach(items) { item in
                ShoppingItemRow(item: item, onToggle: {
                    store.toggleItem(item)
                }, onDelete: {
                    store.deleteItem(item)
                })
            }
        }
    }

    // MARK: - Checked Section
    private var checkedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showCheckedItems.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "00B894"))

                    Text("Erledigt (\(checkedItems.count))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "00B894"))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "00B894").opacity(0.6))
                        .rotationEffect(.degrees(showCheckedItems ? 90 : 0))
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
            .buttonStyle(.plain)

            if showCheckedItems {
                ForEach(checkedItems) { item in
                    ShoppingItemRow(item: item, onToggle: {
                        store.toggleItem(item)
                    }, onDelete: {
                        store.deleteItem(item)
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "6C5CE7").opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "cart")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "6C5CE7").opacity(0.5))
            }

            Text("Deine Einkaufsliste ist leer")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "8B8BA0"))

            Text("Tippe auf + um Artikel hinzuzufügen")
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
                            colors: [Color(hex: "6C5CE7"), Color(hex: "A855F7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(hex: "6C5CE7").opacity(0.5), radius: 16, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Shopping Item Row
struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            item.isChecked
                                ? Color(hex: "00B894")
                                : Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if item.isChecked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "00B894"))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Item Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isChecked ? Color(hex: "6C6C80") : .white)
                    .strikethrough(item.isChecked, color: Color(hex: "6C6C80"))
            }

            Spacer()

            // Quantity Badge
            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(item.category.color.opacity(0.12))
                    }
            }

            // Delete
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "6C6C80"))
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A2E").opacity(item.isChecked ? 0.4 : 0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(item.isChecked ? 0.02 : 0.06), lineWidth: 1)
                }
        }
    }
}

// MARK: - Add Item Sheet
struct AddShoppingItemSheet: View {
    @EnvironmentObject var store: ShoppingStore
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var selectedCategory: ShoppingCategory = .other
    @State private var quantity = 1
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A1A").ignoresSafeArea()

                VStack(spacing: 24) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ARTIKEL")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6C80"))
                            .tracking(1)

                        TextField("z.B. Milch, Brot, Eier...", text: $itemName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .tint(Color(hex: "6C5CE7"))
                            .focused($isNameFocused)
                            .padding(16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "1A1A2E"))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "6C5CE7").opacity(isNameFocused ? 0.5 : 0), lineWidth: 2)
                                    }
                            }
                    }

                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KATEGORIE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6C80"))
                            .tracking(1)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ShoppingCategory.allCases) { category in
                                    categoryChip(category)
                                }
                            }
                        }
                    }

                    // Quantity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MENGE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "6C6C80"))
                            .tracking(1)

                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background {
                                        Circle()
                                            .fill(Color(hex: "1A1A2E"))
                                    }
                            }

                            Text("\(quantity)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 60)

                            Button {
                                if quantity < 99 { quantity += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background {
                                        Circle()
                                            .fill(Color(hex: "6C5CE7"))
                                    }
                            }
                        }
                    }

                    Spacer()

                    // Add Button
                    Button {
                        guard !itemName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let item = ShoppingItem(
                            name: itemName.trimmingCharacters(in: .whitespaces),
                            category: selectedCategory,
                            quantity: quantity
                        )
                        store.addItem(item)
                        dismiss()
                    } label: {
                        Text("Hinzufügen")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: itemName.isEmpty
                                                ? [Color(hex: "2A2A3E"), Color(hex: "2A2A3E")]
                                                : [Color(hex: "6C5CE7"), Color(hex: "A855F7")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Neuer Artikel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(Color(hex: "6C5CE7"))
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private func categoryChip(_ category: ShoppingCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selectedCategory == category ? .white : category.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(selectedCategory == category
                          ? category.color
                          : category.color.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
