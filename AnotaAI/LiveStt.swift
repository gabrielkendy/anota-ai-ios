import AVFoundation
import Foundation
import Speech

@MainActor
final class LiveStt: ObservableObject {
    @Published var parcial = ""
    @Published var finalizado = ""
    @Published var ouvindo = false
    @Published var erro: String?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))

    func pedirPermissao() async -> Bool {
        let fala = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                c.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { ok in
                c.resume(returning: ok)
            }
        }
        return fala && mic
    }

    func iniciar() {
        guard let recognizer, recognizer.isAvailable else {
            erro = "reconhecimento indisponivel"
            return
        }

        do {
            let sessao = AVAudioSession.sharedInstance()
            try sessao.setCategory(.record, mode: .measurement, options: .duckOthers)
            try sessao.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.erro = error.localizedDescription
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        let input = audioEngine.inputNode
        let formato = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: formato) { buffer, _ in
            req.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.erro = error.localizedDescription
            return
        }

        ouvindo = true
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    if result.isFinal {
                        let f = result.bestTranscription.formattedString
                        if !f.isEmpty {
                            self.finalizado += (self.finalizado.isEmpty ? "" : " ") + f
                        }
                        self.parcial = ""
                    } else {
                        self.parcial = result.bestTranscription.formattedString
                    }
                }
                if error != nil, self.ouvindo {
                    self.reagendarReinicio()
                }
            }
        }
    }

    private func reagendarReinicio() {
        guard ouvindo else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.ouvindo else { return }
            self.parar()
            self.iniciar()
        }
    }

    func parar() {
        ouvindo = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        parcial = ""
    }
}
