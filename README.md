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

## Status do build
- **Compila verde na CI** — GitHub Actions, runner macOS 15 (Xcode 16).
- Ultimo run verde: 15/10/2026, workflow "iOS Build" (`workflow_dispatch`).
- Artefatos do run: `AnotaAI-app` (o .app) e `AnotaAI-ipa` (o .ipa sem assinatura).
- Copia local pronta para instalar: `dist/ANOTA-AI-iOS-0.1.0.ipa`.

## Como instalar no iPhone (sem Mac)
1. Instale o Sideloadly no Windows: https://sideloadly.io
2. Conecte o iPhone por cabo e abra o Sideloadly.
3. Arraste `dist/ANOTA-AI-iOS-0.1.0.ipa` para dentro do Sideloadly.
4. Digite seu Apple ID quando ele pedir (fica so no seu PC, nada vai para servidor).
5. Clique "Start" — ele assina com o seu ID e instala no aparelho.

Obs: com Apple ID gratis o app fica valido por 7 dias (rodar o Sideloadly de novo
renova). Com conta Apple Developer (US$ 99/ano) vale 1 ano, sem re-assinar.
Sem conta nenhuma nao instala: a Apple exige assinatura para app fora da loja.

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
Workflow em `.github/workflows/ios-build.yml` (runner macOS):
compila com `CODE_SIGNING_ALLOWED=NO`, guarda o `.app` e empacota o `.ipa`
(`Payload/ANOTA AI.app`) como artefatos do run. Os dois downloads ficam na
pagina do run, em "Artifacts".
