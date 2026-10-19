import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var modelo: AppModel
    @State private var email = ""
    @State private var senha = ""
    @State private var entrando = false
    @State private var aviso: String?
    @State private var pedindoEmail = false
    @State private var emailRecuperacao = ""
    @State private var sessaoWeb: ASWebAuthenticationSession?
    private let ancora = AncoraWeb()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("ANOTA AÍ")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AnotaCores.grafite)
            Text("Suas reunioes, anotadas.")
                .foregroundColor(AnotaCores.cinzaTexto)

            Spacer().frame(height: 18)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))

            SecureField("Senha", text: $senha)
                .textContentType(.password)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))

            Button("Esqueci minha senha") {
                emailRecuperacao = email
                pedindoEmail = true
            }
            .font(.footnote)
            .foregroundColor(AnotaCores.cinzaTexto)
            .frame(maxWidth: .infinity, alignment: .center)

            if let erro = modelo.erro {
                Text(erro)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button {
                Task {
                    entrando = true
                    await modelo.entrar(email: email, senha: senha)
                    entrando = false
                }
            } label: {
                Group {
                    if entrando {
                        ProgressView().tint(.white)
                    } else {
                        Text("Entrar").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AnotaCores.grafite)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || senha.isEmpty || entrando)

            Button {
                abrirLoginGoogle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text("Entrar com Google").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(AnotaCores.grafite)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AnotaCores.grafite.opacity(0.25)))
            }
            .disabled(entrando)

            Text("Quem criou a conta pelo Google entra por aqui.")
                .font(.caption)
                .foregroundColor(AnotaCores.cinzaTexto)

            Spacer()
            Spacer()
        }
        .padding(24)
        .background(AnotaCores.fundo.ignoresSafeArea())
        .onAppear {
            if email.isEmpty { email = modelo.email }
        }
        .alert("Recuperar senha", isPresented: $pedindoEmail) {
            TextField("Email da conta", text: $emailRecuperacao)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            Button("Enviar link") {
                Task { aviso = await modelo.recuperarSenha(emailRecuperacao) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Enviamos um link para você criar uma senha nova.")
        }
        .alert("Pronto", isPresented: Binding(
            get: { aviso != nil },
            set: { if !$0 { aviso = nil } }
        )) {
            Button("Ok") { aviso = nil }
        } message: {
            Text(aviso ?? "")
        }
    }

    /// Abre a página do nosso servidor; o Google devolve `anota://login-complete?code=...`.
    private func abrirLoginGoogle() {
        let verifier = LoginGoogle.novoVerifier()
        Session.verifierGoogle = verifier
        let url = LoginGoogle.url(verifier: verifier, state: UUID().uuidString)

        let sessao = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: LoginGoogle.esquema
        ) { callback, _ in
            guard
                let callback,
                let partes = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                let code = partes.queryItems?.first(where: { $0.name == "code" })?.value
            else { return }
            Task { await modelo.entrarComGoogle(code: code) }
        }
        sessao.presentationContextProvider = ancora
        sessao.prefersEphemeralWebBrowserSession = false
        sessao.start()
        sessaoWeb = sessao
    }
}
