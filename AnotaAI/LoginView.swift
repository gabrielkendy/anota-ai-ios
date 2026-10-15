import SwiftUI

struct LoginView: View {
    @EnvironmentObject var modelo: AppModel
    @State private var email = ""
    @State private var senha = ""
    @State private var entrando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Text("ANOTA AI")
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

            Spacer()
            Spacer()
        }
        .padding(24)
        .background(AnotaCores.fundo.ignoresSafeArea())
    }
}
