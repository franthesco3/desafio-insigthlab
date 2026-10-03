# ADR 005 — Sessão no cofre do SO e store SQLite criptografado

**Status:** aceito

## Contexto

O cliente precisa restaurar a sessão sem pedir senha (RF08) e guarda localmente mensagens e chaves de criptografia ponta a ponta. Tokens e chaves em disco, em texto plano, permitiriam sequestrar a conta ou ler conversas a partir de um backup ou de outro usuário do computador.

## Decisão

- A sessão (`user_id`, `device_id`, `access_token`, `refresh_token`, URL do homeserver) é gravada **somente no cofre do SO** via `flutter_secure_storage`: Keychain (macOS), Credential Manager (Windows), libsecret (Linux).
- O store SQLite do SDK é **criptografado com uma passphrase aleatória de 32 bytes**, gerada no primeiro login e também guardada no cofre.
- O login recria o store do zero; o logout invalida o token no servidor, apaga o store e limpa o cofre — mesmo sem rede.
- Tipos sensíveis (`SessionDto` no Rust; `StoredSession` e `LoginCredentials` no Dart) têm `Debug`/`toString` que omitem tokens e senha. O `AppLogger` aplica redação adicional (tokens `syt_…`, `Bearer`, `access_token`/`password`/`passphrase`) e não escreve nada em release.
- No macOS, usa-se o Keychain clássico (`usesDataProtectionKeychain: false`), que dispensa conta de desenvolvedor Apple para rodar localmente.

## Consequências

- Roubar o diretório de dados do app não basta para usar a conta nem ler mensagens.
- Se o cofre for apagado (ou o usuário trocar de máquina), a sessão e o store local se perdem e é preciso logar de novo.
- No Linux, é necessário um serviço de secrets (gnome-keyring/KWallet) em execução.
- Logout offline não invalida o token no servidor (limitação documentada no README).
