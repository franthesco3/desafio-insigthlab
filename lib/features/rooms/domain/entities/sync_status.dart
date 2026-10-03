/// Estado da sincronização com o homeserver.
enum SyncStatus {
  /// Sync ainda não iniciado.
  idle,

  /// Primeira sincronização em andamento.
  syncing,

  /// Sincronizado e recebendo atualizações em tempo real.
  running,

  /// Sem conexão; o SDK tentará reconectar.
  offline,

  /// Sync interrompido por erro.
  error,
}
