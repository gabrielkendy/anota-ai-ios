import Foundation

enum ApiErro: LocalizedError {
    case http(Int, String)
    case vazio(String)

    var errorDescription: String? {
        switch self {
        case .http(let c, let t): return "HTTP \(c): \(t)"
        case .vazio(let m): return m
        }
    }
}

enum Api {
    static let base = URL(string: "https://anotaai.agenciabase.tech")!

    private static func post(_ path: String, corpo: [String: Any], token: String? = nil) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: corpo)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw ApiErro.vazio("sem resposta") }
        guard (200..<300).contains(http.statusCode) else {
            throw ApiErro.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    static func login(email: String, senha: String, lembrar: Bool = true) async throws -> Tokens {
        let data = try await post("v1/auth", corpo: ["email": email, "password": senha, "remember": lembrar])
        return try JSONDecoder().decode(Tokens.self, from: data)
    }

    private struct WorkosResp: Decodable {
        struct T: Decodable {
            struct U: Decodable {
                let id: String?
                let email: String?
            }
            let access_token: String
            let refresh_token: String?
            let user: U?
        }
        let tokens: T
    }

    /// Login com Google: troca o code do deep link pela sessão.
    static func loginComGoogle(code: String, verifier: String) async throws -> SessaoGoogle {
        let data = try await post(
            "v1/workos-auth-complete",
            corpo: ["code": code, "codeVerifier": verifier, "platform": "ios"]
        )
        let r = try JSONDecoder().decode(WorkosResp.self, from: data)
        let tokens = Tokens(
            access_token: r.tokens.access_token,
            refresh_token: r.tokens.refresh_token,
            user_id: r.tokens.user?.id
        )
        return SessaoGoogle(tokens: tokens, email: r.tokens.user?.email ?? "")
    }

    struct SessaoGoogle {
        let tokens: Tokens
        let email: String
    }

    /// Recuperar senha: pede o link por e-mail e devolve a mensagem do servidor.
    static func recuperarSenha(email: String) async throws -> String {
        let data = try await post("v1/recuperar-senha", corpo: ["email": email])
        if let d = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let m = d["mensagem"] as? String {
            return m
        }
        return "Se este e-mail tiver conta, o link para criar nova senha chegou nele."
    }

    /// Definir senha de quem entrou pelo Google (para entrar sem Google depois).
    static func definirSenha(token: String, novaSenha: String) async throws {
        _ = try await post("v1/definir-senha", corpo: ["nova_senha": novaSenha], token: token)
    }

    static func documentos(token: String) async throws -> [Doc] {
        let data = try await post("v1/get-documents", corpo: [:], token: token)
        return try JSONDecoder().decode(DocsResp.self, from: data).documents
    }

    static func criarDocumento(token: String, titulo: String) async throws -> Doc {
        let data = try await post("v1/create-document", corpo: ["title": titulo], token: token)
        guard let doc = try JSONDecoder().decode(DocResp.self, from: data).document else {
            throw ApiErro.vazio("create-document sem document")
        }
        return doc
    }

    static func anexarTranscricao(token: String, docId: String, texto: String) async throws -> Int {
        let data = try await post("v1/insert-transcriptions", corpo: ["document_id": docId, "chunks": [texto]], token: token)
        return (try? JSONDecoder().decode(InsertResp.self, from: data).total) ?? 0
    }

    static func transcricao(token: String, docId: String) async throws -> String {
        let data = try await post("v1/get-document-transcript", corpo: ["input": ["document_id": docId]], token: token)
        let chunks = (try? JSONDecoder().decode([Chunk].self, from: data)) ?? []
        return chunks.compactMap { $0.text }.joined(separator: "\n")
    }

    static func resumir(token: String, transcricao: String) async throws -> String {
        let data = try await post("v1/generate-transcript", corpo: ["transcript": transcricao], token: token)
        guard let s = try JSONDecoder().decode(SummaryResp.self, from: data).summary, !s.isEmpty else {
            throw ApiErro.vazio("resumo vazio")
        }
        return s
    }

    static func salvarResumo(token: String, docId: String, resumo: String) async throws {
        _ = try await post("v1/update-document", corpo: ["id": docId, "summary": resumo], token: token)
    }
}
