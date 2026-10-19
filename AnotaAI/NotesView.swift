import SwiftUI

struct NotesView: View {
    @EnvironmentObject var modelo: AppModel
    @State private var mostrarGravar = false
    @State private var pedindoSenha = false
    @State private var novaSenha = ""

    var body: some View {
        NavigationStack {
            Group {
                if modelo.carregandoNotas && modelo.notas.isEmpty {
                    ProgressView("Carregando...")
                } else if modelo.notas.isEmpty {
                    VStack(spacing: 10) {
                        Text("Nenhuma nota ainda")
                            .font(.headline)
                            .foregroundColor(AnotaCores.grafite)
                        Text("Toque em Gravar e fale.")
                            .foregroundColor(AnotaCores.cinzaTexto)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(modelo.notas) { doc in
                        NavigationLink {
                            NoteDetailView(doc: doc)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(doc.title ?? "Sem titulo")
                                    .font(.headline)
                                    .foregroundColor(AnotaCores.grafite)
                                Text(Self.formata(doc.created_at))
                                    .font(.caption)
                                    .foregroundColor(AnotaCores.cinzaTexto)
                                if let pre = doc.summary ?? doc.transcript, !pre.isEmpty {
                                    Text(pre)
                                        .font(.subheadline)
                                        .foregroundColor(AnotaCores.cinzaTexto)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await modelo.carregarNotas() }
                }
            }
            .navigationTitle("ANOTA AÍ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        pedindoSenha = true
                    } label: {
                        Image(systemName: "lock.rotation")
                    }
                    .accessibilityLabel("Trocar senha")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") { modelo.sair() }
                }
            }
            .alert("Trocar senha", isPresented: $pedindoSenha) {
                SecureField("Senha nova (8+)", text: $novaSenha)
                Button("Salvar") {
                    let s = novaSenha
                    novaSenha = ""
                    Task { await modelo.trocarSenha(s) }
                }
                Button("Cancelar", role: .cancel) { novaSenha = "" }
            } message: {
                Text("Escolha a senha nova da sua conta. Minimo 8 caracteres.")
            }
            .alert("Senha", isPresented: Binding(
                get: { modelo.avisoSenha != nil },
                set: { if !$0 { modelo.avisoSenha = nil } }
            )) {
                Button("Ok") { modelo.avisoSenha = nil }
            } message: {
                Text(modelo.avisoSenha ?? "")
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    mostrarGravar = true
                } label: {
                    Label("Gravar", systemImage: "mic.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AnotaCores.laranja)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $mostrarGravar) {
                RecordView()
                    .environmentObject(modelo)
            }
            .task { await modelo.carregarNotas() }
        }
    }

    static func formata(_ iso: String?) -> String {
        guard let iso, iso.count >= 16 else { return "" }
        return String(iso.prefix(16)).replacingOccurrences(of: "T", with: " ")
    }
}
