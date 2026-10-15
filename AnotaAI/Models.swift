import Foundation

struct Tokens: Decodable {
    let access_token: String
    let refresh_token: String?
    let user_id: String?
}

struct Doc: Decodable, Identifiable {
    let id: String
    let title: String?
    let created_at: String?
    let updated_at: String?
    let transcript: String?
    let summary: String?
}

struct DocsResp: Decodable { let documents: [Doc] }
struct DocResp: Decodable { let document: Doc? }
struct SummaryResp: Decodable { let summary: String? }
struct InsertResp: Decodable { let ok: Bool?; let total: Int? }
struct Chunk: Decodable { let text: String? }
