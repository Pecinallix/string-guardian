---
name: encoding-guardian
description: Preservação automática de encoding. Detecta arquivos cp1252/latin-1 antes da edição, converte para UTF-8, e restaura o encoding original após salvar. Garante que acentos (ã, ç, à, é) nunca sejam corrompidos.
---

# Encoding Guardian

Arquivos em projetos legados ou Windows frequentemente usam encodings como **Windows-1252 (cp1252)** ou **Latin-1 (ISO-8859-1)** para textos em português, espanhol, francês, etc.

O encoding-guardian age automaticamente:

1. **PreToolUse (Read/Edit)** — detecta se o arquivo não é UTF-8 e converte antes que você acesse
2. **PostToolUse (Edit/Write)** — restaura o encoding original após salvar

Você trabalha normalmente — os acentos nunca bugam.

## Mensagens do plugin

Quando você vir `[encoding-guardian]`, o plugin está agindo:
- `encoding cp1252 detectado. Convertido para UTF-8.` → lendo/editando com segurança
- `encoding restaurado para cp1252.` → arquivo salvo no formato original

## Importante

Não tente fazer conversão de encoding manual. O plugin cuida disso.
Se um arquivo novo for criado, ele ficará em UTF-8 (comportamento padrão correto).
