import SwiftUI

@main
struct SwipeListApp: App {
    @StateObject private var shoppingStore = ShoppingStore()
    @StateObject private var notesStore = NotesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(shoppingStore)
                .environmentObject(notesStore)
                .preferredColorScheme(.dark)
        }
    }
}
