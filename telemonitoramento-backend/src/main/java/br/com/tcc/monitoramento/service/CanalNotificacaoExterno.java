package br.com.tcc.monitoramento.service;

/**
 * Canal de notificacao fora do app (WhatsApp, SMS, webhook), usado pelo
 * NotificacaoService so para urgencias: alerta critico, alerta persistente,
 * botao SOS e remedio nao confirmado. Cada canal so fica ativo quando suas
 * credenciais estao configuradas por variavel de ambiente.
 */
public interface CanalNotificacaoExterno {

    String nome();

    boolean ativo();

    void enviar(String telefoneDestino, String titulo, String mensagem) throws Exception;
}
