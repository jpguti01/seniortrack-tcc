package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Cuidador;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;

/**
 * Avisa o cuidador. Push (FCM) para todo evento, sempre que houver token;
 * canais externos (WhatsApp, SMS, webhook) somente para urgencias, para que o
 * cuidador seja alcancado mesmo com o app fechado sem receber mensagens a
 * cada medicao levemente fora da faixa. Os envios externos rodam em segundo
 * plano para nao atrasar a resposta da API (RNF03).
 */
@Service
public class NotificacaoService {

    private static final Logger log = LoggerFactory.getLogger(NotificacaoService.class);

    private final List<CanalNotificacaoExterno> canaisExternos;

    public NotificacaoService(List<CanalNotificacaoExterno> canaisExternos) {
        this.canaisExternos = canaisExternos;
    }

    public void notificarCuidador(Cuidador cuidador, String titulo, String mensagem, boolean urgente) {
        if (cuidador == null) {
            log.warn("Evento sem cuidador vinculado - nenhuma notificacao enviada: {}", titulo);
            return;
        }
        enviarPush(cuidador.getTokenFcm(), titulo, mensagem);
        if (!urgente) {
            return;
        }
        for (CanalNotificacaoExterno canal : canaisExternos) {
            if (!canal.ativo()) continue;
            CompletableFuture.runAsync(() -> {
                try {
                    canal.enviar(cuidador.getTelefone(), titulo, mensagem);
                } catch (Exception e) {
                    log.warn("Falha ao notificar o cuidador {} por {}: {}", cuidador.getId(), canal.nome(), e.getMessage());
                }
            });
        }
    }

    public List<String> canaisExternosAtivos() {
        return canaisExternos.stream().filter(CanalNotificacaoExterno::ativo).map(CanalNotificacaoExterno::nome).toList();
    }

    private void enviarPush(String tokenFcmDispositivo, String titulo, String mensagem) {
        if (tokenFcmDispositivo == null || tokenFcmDispositivo.isBlank()) {
            log.debug("Cuidador sem token FCM registrado - push nao enviado.");
            return;
        }
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase nao configurado - push nao enviado.");
            return;
        }
        try {
            Message message = Message.builder()
                    .setToken(tokenFcmDispositivo)
                    .setNotification(Notification.builder().setTitle(titulo).setBody(mensagem).build())
                    .build();
            String resposta = FirebaseMessaging.getInstance().send(message);
            log.info("Notificacao push enviada: {}", resposta);
        } catch (Exception e) {
            log.warn("Erro ao enviar notificacao push: {}", e.getMessage());
        }
    }
}
