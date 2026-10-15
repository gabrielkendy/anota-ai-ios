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

    static func login(email: String, senha: String) async throws -> Tokens {
        let data = try await post("v1/auth", corpo: ["email": email, "password": senha])
        return try JSONDecoder().decode(Tokens.self, from: data)
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
