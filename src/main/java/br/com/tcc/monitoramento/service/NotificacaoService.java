package br.com.tcc.monitoramento.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class NotificacaoService {

    public void enviarAlertaLimiar(String tokenFcmDispositivo, String mensagemAlerta) {
        if (tokenFcmDispositivo == null || tokenFcmDispositivo.isEmpty()) {
            System.out.println("O paciente não possui um token FCM registado.");
            return;
        }

        try {
            Notification notification = Notification.builder()
                    .setTitle("🚨 Alerta de Sinal Vital!")
                    .setBody(mensagemAlerta)
                    .build();

            Message message = Message.builder()
                    .setToken(tokenFcmDispositivo)
                    .setNotification(notification)
                    .build();

            String resposta = FirebaseMessaging.getInstance().send(message);
            System.out.println("Notificação enviada com sucesso! ID: " + resposta);

        } catch (Exception e) {
            System.err.println("Erro ao enviar notificação push: " + e.getMessage());
        }
    }
}