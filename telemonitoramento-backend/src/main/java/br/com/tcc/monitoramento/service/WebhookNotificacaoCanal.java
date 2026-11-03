package br.com.tcc.monitoramento.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Envia a urgencia em JSON para uma URL configurada (NOTIFICACAO_WEBHOOK_URL),
 * para integrar com ferramentas como n8n, Make ou Zapier, que repassam a
 * mensagem para WhatsApp, SMS, e-mail ou outro canal escolhido. Se
 * NOTIFICACAO_WEBHOOK_TOKEN for definido, vai no header X-SeniorTrack-Token.
 */
@Component
public class WebhookNotificacaoCanal implements CanalNotificacaoExterno {

    private static final Logger log = LoggerFactory.getLogger(WebhookNotificacaoCanal.class);

    private final String url;
    private final String token;
    private final ObjectMapper objectMapper;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public WebhookNotificacaoCanal(@Value("${notificacao.webhook.url:}") String url,
                                   @Value("${notificacao.webhook.token:}") String token,
                                   ObjectMapper objectMapper) {
        this.url = url;
        this.token = token;
        this.objectMapper = objectMapper;
    }

    @Override
    public String nome() {
        return "Webhook";
    }

    @Override
    public boolean ativo() {
        return !url.isBlank();
    }

    @Override
    public void enviar(String telefoneDestino, String titulo, String mensagem) throws Exception {
        Map<String, Object> corpo = new LinkedHashMap<>();
        corpo.put("titulo", titulo);
        corpo.put("mensagem", mensagem);
        corpo.put("telefone", telefoneDestino);
        corpo.put("telefoneE164", TwilioNotificacaoCanal.paraE164(telefoneDestino).orElse(null));
        corpo.put("enviadoEm", LocalDateTime.now().toString());

        HttpRequest.Builder requisicao = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(10))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(corpo)));
        if (!token.isBlank()) {
            requisicao.header("X-SeniorTrack-Token", token);
        }
        HttpResponse<Void> resposta = http.send(requisicao.build(), HttpResponse.BodyHandlers.discarding());
        if (resposta.statusCode() >= 300) {
            log.warn("Webhook de notificacao respondeu HTTP {}.", resposta.statusCode());
        }
    }
}
