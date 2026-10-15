import Foundation

enum Session {
    private static let d = UserDefaults.standard

    static var token: String? {
        get { d.string(forKey: "access_token") }
        set { d.set(newValue, forKey: "access_token") }
    }

    static var email: String? {
        get { d.string(forKey: "email") }
        set { d.set(newValue, forKey: "email") }
    }

    static func salvar(_ t: Tokens, email: String) {
        Self.token = t.access_token
        d.set(t.refresh_token, forKey: "refresh_token")
        Self.email = email
    }

    static func limpar() {
        d.removeObject(forKey: "access_token")
        d.removeObject(forKey: "refresh_token")
        d.removeObject(forKey: "email")
    }
}
