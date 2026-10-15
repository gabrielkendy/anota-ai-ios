import SwiftUI

struct RecordView: View {
    @EnvironmentObject var modelo: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var stt = LiveStt()
    @State private var salvando = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(stt.ouvindo ? "Ouvindo..." : "Pronto para ouvir.")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(stt.ouvindo ? AnotaCores.laranja : AnotaCores.cinzaTexto)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if stt.finalizado.isEmpty && stt.parcial.isEmpty {
                            Text("A transcricao aparece aqui enquanto voce fala.")
                                .foregroundColor(AnotaCores.cinzaTexto)
                        } else {
                            Text(stt.finalizado)
                                .foregroundColor(AnotaCores.grafite)
                            if !stt.parcial.isEmpty {
                                Text(stt.parcial)
                                    .foregroundColor(AnotaCores.cinzaTexto)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                }
                .frame(maxHeight: .infinity)

                Button {
                    if stt.ouvindo {
                        Task { await pararESalvar() }
                    } else {
                        Task {
                            let ok = await stt.pedirPermissao()
                            guard ok else {
                                stt.erro = "permissao de microfone/fala negada"
                                return
                            }
                            stt.iniciar()
                        }
                    }
                } label: {
                    Group {
                        if salvando {
                            ProgressView().tint(.white)
                        } else {
                            Text(stt.ouvindo ? "Parar e salvar nota" : "Comecar a gravar")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(stt.ouvindo ? AnotaCores.laranja : AnotaCores.grafite)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(salvando)

                if let e = stt.erro {
                    Text(e).font(.footnote).foregroundColor(.red)
                }

                Text("A nota e salva no seu ANOTA AI e aparece tambem no desktop.")
                    .font(.footnote)
                    .foregroundColor(AnotaCores.cinzaTexto)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(AnotaCores.fundo.ignoresSafeArea())
            .navigationTitle("Gravar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") {
                        stt.parar()
                        dismiss()
                    }
                }
            }
        }
    }

    private func pararESalvar() async {
        let texto = (stt.finalizado + " " + stt.parcial).trimmingCharacters(in: .whitespacesAndNewlines)
        stt.parar()
        guard !texto.isEmpty else {
            dismiss()
            return
        }
        salvando = true
        let f = DateFormatter()
        f.dateFormat = "dd/MM HH:mm"
        let titulo = "Reuniao " + f.string(from: Date())
        _ = await modelo.criarNotaPorVoz(titulo: titulo, texto: texto)
        salvando = false
        dismiss()
    }
}
