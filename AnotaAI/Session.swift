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

    /// Último e-mail usado, para o campo já vir preenchido no login.
    static var ultimoEmail: String? {
        get { d.string(forKey: "ultimo_email") }
        set { d.set(newValue, forKey: "ultimo_email") }
    }

    /// Verifier do PKCE que precisa sobreviver até o Google devolver o code.
    static var verifierGoogle: String? {
        get { d.string(forKey: "google_verifier") }
        set { d.set(newValue, forKey: "google_verifier") }
    }

    static func salvar(_ t: Tokens, email: String) {
        Self.token = t.access_token
        d.set(t.refresh_token, forKey: "refresh_token")
        Self.email = email
        Self.ultimoEmail = email
        d.removeObject(forKey: "google_verifier")
    }

    static func limpar() {
        let ultimo = ultimoEmail
        d.removeObject(forKey: "access_token")
        d.removeObject(forKey: "refresh_token")
        d.removeObject(forKey: "email")
        d.removeObject(forKey: "google_verifier")
        // "memória de login": guarda só o e-mail para a próxima vez
        if let ultimo { Self.ultimoEmail = ultimo }
    }
}
