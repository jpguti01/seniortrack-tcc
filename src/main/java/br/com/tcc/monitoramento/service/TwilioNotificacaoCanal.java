package br.com.tcc.monitoramento.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Envia SMS e/ou WhatsApp pela API REST da Twilio. Fica desativado ate que
 * TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN e ao menos um remetente
 * (TWILIO_FROM_SMS ou TWILIO_FROM_WHATSAPP) sejam definidos.
 */
@Component
public class TwilioNotificacaoCanal implements CanalNotificacaoExterno {

    private static final Logger log = LoggerFactory.getLogger(TwilioNotificacaoCanal.class);

    private final String accountSid;
    private final String authToken;
    private final String remetenteSms;
    private final String remetenteWhatsapp;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public TwilioNotificacaoCanal(@Value("${notificacao.twilio.account-sid:}") String accountSid,
                                  @Value("${notificacao.twilio.auth-token:}") String authToken,
                                  @Value("${notificacao.twilio.from-sms:}") String remetenteSms,
                                  @Value("${notificacao.twilio.from-whatsapp:}") String remetenteWhatsapp) {
        this.accountSid = accountSid;
        this.authToken = authToken;
        this.remetenteSms = remetenteSms;
        this.remetenteWhatsapp = remetenteWhatsapp;
    }

    @Override
    public String nome() {
        List<String> nomes = new ArrayList<>();
        if (!remetenteSms.isBlank()) nomes.add("SMS");
        if (!remetenteWhatsapp.isBlank()) nomes.add("WhatsApp");
        return nomes.isEmpty() ? "Twilio" : String.join("/", nomes);
    }

    @Override
    public boolean ativo() {
        return !accountSid.isBlank() && !authToken.isBlank()
                && (!remetenteSms.isBlank() || !remetenteWhatsapp.isBlank());
    }

    @Override
    public void enviar(String telefoneDestino, String titulo, String mensagem) throws Exception {
        Optional<String> destino = paraE164(telefoneDestino);
        if (destino.isEmpty()) {
            log.info("Telefone do cuidador ausente ou ficticio; SMS/WhatsApp nao enviado.");
            return;
        }
        String corpo = titulo + "\n" + mensagem + "\n\nSeniorTrack";
        if (!remetenteSms.isBlank()) {
            postar(destino.get(), remetenteSms, corpo);
        }
        if (!remetenteWhatsapp.isBlank()) {
            postar("whatsapp:" + destino.get(), "whatsapp:" + remetenteWhatsapp.replace("whatsapp:", ""), corpo);
        }
    }

    private void postar(String para, String de, String corpo) throws Exception {
        String formulario = Map.of("To", para, "From", de, "Body", corpo).entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
        String credencial = Base64.getEncoder()
                .encodeToString((accountSid + ":" + authToken).getBytes(StandardCharsets.UTF_8));
        HttpRequest requisicao = HttpRequest.newBuilder()
                .uri(URI.create("https://api.twilio.com/2010-04-01/Accounts/" + accountSid + "/Messages.json"))
                .timeout(Duration.ofSeconds(10))
                .header("Authorization", "Basic " + credencial)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(formulario))
                .build();
        HttpResponse<String> resposta = http.send(requisicao, HttpResponse.BodyHandlers.ofString());
        if (resposta.statusCode() >= 300) {
            log.warn("Twilio recusou o envio para {} (HTTP {}).", para.startsWith("whatsapp:") ? "WhatsApp" : "SMS",
                    resposta.statusCode());
        }
    }

    // Converte um telefone brasileiro como "(11) 98765-4321" para "+5511987654321".
    // Numeros ficticios da demonstracao, como "(11) 00000-0000", sao ignorados.
    static Optional<String> paraE164(String telefone) {
        if (telefone == null) return Optional.empty();
        String digitos = telefone.replaceAll("\\D", "");
        if (digitos.length() == 10 || digitos.length() == 11) {
            digitos = "55" + digitos;
        }
        if (digitos.length() < 12 || digitos.length() > 13 || !digitos.startsWith("55")) {
            return Optional.empty();
        }
        if (digitos.substring(4).chars().allMatch(c -> c == '0')) {
            return Optional.empty();
        }
        return Optional.of("+" + digitos);
    }
}
