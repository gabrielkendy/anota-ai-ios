import SwiftUI

@main
struct AnotaAIApp: App {
    @StateObject private var modelo = AppModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if modelo.logado {
                    NotesView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(modelo)
            .tint(AnotaCores.laranja)
        }
    }
}
