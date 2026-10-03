# ADR 004 — matrix-sdk-ui para sync, lista de salas e timeline

**Status:** aceito

## Contexto

Um cliente precisa de sync contínuo, lista de salas ordenada com prévia e não lidas, timeline com paginação e envio com feedback imediato. Implementar isso sobre o `matrix-sdk` "cru" (sync v2, event handlers, fila de envio) é muito código sujeito a erros sutis (deduplicação, ordenação, reconciliação de local echo).

## Decisão

Usar os componentes de alto nível do `matrix-sdk-ui`:

- **`SyncService`** (com `with_offline_mode`) para o sync loop com reconexão automática; o estado combinado com o do `RoomListService` vira `SyncStateDto`.
- **`RoomListService`** com filtro `non_left` para a lista de salas; o **event cache** do SDK calcula a última mensagem de cada sala.
- **`Timeline`** por sala, criada sob demanda e mantida em `sync_runtime` para que stream, paginação, envio, reenvio e recibo de leitura usem a mesma instância.
- **Local echo:** `Timeline::send` coloca a mensagem na timeline como *enviando*; o próprio stream a atualiza para *enviada* ou *falhou*. O reenvio usa o `SendHandle` do item (`unwedge`) e reativa a fila da sala.
- Os streams entregam ao Dart a **lista completa** (salas ou mensagens) a cada lote de mudanças, e não os *diffs*.

## Consequências

- Muito menos código próprio, e comportamento alinhado aos clientes de referência (Element X usa os mesmos componentes).
- Enviar a lista completa custa O(n) por atualização. Para centenas de itens no desktop isso é desprezível e simplifica muito o Dart; se virar gargalo, a facade pode passar a emitir *diffs* sem mudar o domínio.
- Ficamos sujeitos às mudanças de API do `matrix-sdk-ui` (versão fixada em 0.19.1).
