import SwiftUI

enum Tab: String, CaseIterable {
    case shopping = "Einkaufsliste"
    case notes = "Notizen"

    var icon: String {
        switch self {
        case .shopping: return "cart.fill"
        case .notes: return "note.text"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .shopping
    @State private var tabAnimation: Bool = false
    @EnvironmentObject var shoppingStore: ShoppingStore

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0A1A"),
                    Color(hex: "121228"),
                    Color(hex: "0A0A1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Content
                TabView(selection: $selectedTab) {
                    ShoppingListView()
                        .tag(Tab.shopping)

                    NotesView()
                        .tag(Tab.notes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom Tab Bar
                customTabBar
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A3E").opacity(0.8),
                            Color(hex: "0A0A1A").opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
        }
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if selectedTab == tab {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6C5CE7"), Color(hex: "A855F7")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 32)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))

                        if selectedTab == tab && tab == .shopping {
                            let unchecked = shoppingStore.items.filter { !$0.isChecked }.count
                            if unchecked > 0 {
                                Text("\(unchecked)")
                                    .font(.system(size: 11, weight: .bold))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular))
            }
            .foregroundColor(selectedTab == tab ? .white : .gray)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @Namespace private var tabNamespace
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
