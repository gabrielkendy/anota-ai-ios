import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var token: String? = Session.token
    @Published var email: String = Session.email ?? Session.ultimoEmail ?? ""
    @Published var notas: [Doc] = []
    @Published var carregandoNotas = false
    @Published var erro: String?

    var logado: Bool { token != nil }

    init() {
        if token != nil {
            Task { await carregarNotas() }
        }
    }

    /// Login com Google: recebe o code do navegador e troca pela sessão.
    func entrarComGoogle(code: String) async {
        erro = nil
        guard let verifier = Session.verifierGoogle else {
            erro = "Login com Google expirou. Tente de novo."
            return
        }
        do {
            let sessao = try await Api.loginComGoogle(code: code, verifier: verifier)
            let mail = sessao.email.isEmpty ? (Session.ultimoEmail ?? "") : sessao.email
            Session.salvar(sessao.tokens, email: mail)
            token = sessao.tokens.access_token
            email = mail
            await carregarNotas()
        } catch {
            erro = error.localizedDescription
        }
    }

    /// "Esqueci minha senha": devolve a mensagem para mostrar na tela.
    func recuperarSenha(_ mail: String) async -> String {
        let limpo = mail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard limpo.contains("@") else { return "Digite o e-mail da conta" }
        do {
            return try await Api.recuperarSenha(email: limpo)
        } catch {
            return error.localizedDescription
        }
    }

    /// Define a senha de quem entrou pelo Google.
    func definirSenha(_ nova: String) async -> String {
        guard let t = token else { return "Entre na conta primeiro" }
        guard nova.count >= 8 else { return "A senha precisa ter pelo menos 8 caracteres" }
        do {
            try await Api.definirSenha(token: t, novaSenha: nova)
            return "Senha salva. Você já pode entrar com e-mail e senha."
        } catch {
            return error.localizedDescription
        }
    }

    func entrar(email: String, senha: String) async {
        erro = nil
        do {
            let limpo = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let t = try await Api.login(email: limpo, senha: senha)
            Session.salvar(t, email: limpo)
            token = t.access_token
            self.email = limpo
            await carregarNotas()
        } catch {
            erro = error.localizedDescription
        }
    }

    func sair() {
        Session.limpar()
        token = nil
        notas = []
    }

    func carregarNotas() async {
        guard let t = token else { return }
        carregandoNotas = true
        do {
            notas = try await Api.documentos(token: t)
            erro = nil
        } catch {
            erro = error.localizedDescription
        }
        carregandoNotas = false
    }

    func criarNotaPorVoz(titulo: String, texto: String) async -> Doc? {
        guard let t = token else { return nil }
        do {
            let doc = try await Api.criarDocumento(token: t, titulo: titulo)
            if !texto.isEmpty {
                _ = try await Api.anexarTranscricao(token: t, docId: doc.id, texto: texto)
            }
            await carregarNotas()
            return doc
        } catch {
            erro = error.localizedDescription
            return nil
        }
    }

    func transcricao(docId: String) async -> String {
        guard let t = token else { return "" }
        return (try? await Api.transcricao(token: t, docId: docId)) ?? ""
    }

    func gerarResumo(docId: String, texto: String) async -> String? {
        guard let t = token else { return nil }
        do {
            let r = try await Api.resumir(token: t, transcricao: texto)
            try await Api.salvarResumo(token: t, docId: docId, resumo: r)
            return r
        } catch {
            erro = error.localizedDescription
            return nil
        }
    }
}
