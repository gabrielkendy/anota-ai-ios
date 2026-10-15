# ANOTA AI — App iOS

App nativo (SwiftUI + Speech framework) com o MESMO backend
(`https://anotaai.agenciabase.tech`) e a MESMA identidade do Android.

## O que ja faz
- Login com email/senha (contrato `/v1/auth`, Bearer JWT).
- Lista de notas (`/v1/get-documents`), detalhe com transcricao
  (`/v1/get-document-transcript`) e resumo por IA (`/v1/generate-transcript`).
- Gravar ao vivo: reconhecimento de fala pt-BR do sistema (Speech framework),
  cria a nota (`/v1/create-document`) e anexa a transcricao
  (`/v1/insert-transcriptions`).

## Estrutura
```
mobile-ios/
  project.yml                 # projeto gerado pelo XcodeGen
  gerar-icones-ios.py         # gera o AppIcon a partir de ../brand/anota-ai-appicon.png
  AnotaAI/                    # fontes Swift
    AnotaAIApp.swift  Theme.swift  Models.swift  Api.swift  Session.swift
    AppModel.swift    LiveStt.swift
    LoginView.swift   NotesView.swift  NoteDetailView.swift  RecordView.swift
    Assets.xcassets/  (AppIcon + AccentColor)
```

## Build no Mac
```bash
brew install xcodegen
cd mobile-ios
xcodegen generate          # cria AnotaAI.xcodeproj
open AnotaAI.xcodeproj     # selecione seu time (Signing) e rode
```

## Build via CI (sem Mac)
Workflow pronto em `.github/workflows/ios-build.yml` (runner macOS):
compila com `CODE_SIGNING_ALLOWED=NO` e guarda o `.app` como artefato.
Para instalar no iPhone de verdade: conta Apple Developer (assinatura)
ou build assinado pelo Xcode.

## Pendencia honesta
Este codigo foi escrito com cuidado, mas NAO compilado ainda (nao ha Mac
nesta maquina). O primeiro build no Mac/CI pode pedir ajustes de detalhe.
O contrato com o backend e o mesmo ja provado no Android.
