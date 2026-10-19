import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

/// Login com Google sem SDK: abre a página do nosso servidor no navegador do
/// sistema, o Google devolve o code para o servidor e o servidor devolve
/// `anota://login-complete?code=...` (mesmo caminho do app de computador).
enum LoginGoogle {
    static let base = "https://anotaai.agenciabase.tech"
    static let esquema = "anota"

    /// 32 bytes aleatórios em base64url = 43 caracteres (limite do PKCE: 43-128).
    static func novoVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URL()
    }

    static func challenge(_ verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URL()
    }

    static func url(verifier: String, state: String) -> URL {
        var c = URLComponents(string: "\(base)/v1/auth")!
        c.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "code_challenge", value: challenge(verifier)),
            URLQueryItem(name: "state", value: state),
        ]
        return c.url!
    }
}

extension Data {
    func base64URL() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

/// Diz ao sistema de onde a janela de login deve sair.
final class AncoraWeb: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let cena = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return cena?.keyWindow ?? ASPresentationAnchor()
    }
}
