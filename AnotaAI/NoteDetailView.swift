import SwiftUI

struct NoteDetailView: View {
    let doc: Doc
    @EnvironmentObject var modelo: AppModel
    @State private var texto = ""
    @State private var resumo = ""
    @State private var gerando = false
    @State private var carregando = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(NotesView.formata(doc.created_at))
                    .font(.caption)
                    .foregroundColor(AnotaCores.cinzaTexto)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumo")
                        .font(.headline)
                        .foregroundColor(AnotaCores.grafite)
                    if !resumo.isEmpty {
                        Text(resumo).foregroundColor(AnotaCores.grafite)
                    } else {
                        Button {
                            Task {
                                gerando = true
                                resumo = await modelo.gerarResumo(docId: doc.id, texto: texto) ?? ""
                                gerando = false
                            }
                        } label: {
                            Group {
                                if gerando {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Gerar resumo").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AnotaCores.grafite)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(texto.isEmpty || gerando)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcricao")
                        .font(.headline)
                        .foregroundColor(AnotaCores.grafite)
                    if carregando {
                        ProgressView()
                    } else {
                        Text(texto.isEmpty ? "sem transcricao" : texto)
                            .foregroundColor(AnotaCores.grafite)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(AnotaCores.fundo.ignoresSafeArea())
        .navigationTitle(doc.title ?? "Nota")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let t = doc.transcript, !t.isEmpty {
                texto = t
            } else {
                texto = await modelo.transcricao(docId: doc.id)
            }
            if let r = doc.summary { resumo = r }
            carregando = false
        }
    }
}
