package br.com.tcc.monitoramento.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.Map;

/** Os códigos são gerados e validados pelo Twilio Verify; nunca retornam à API. */
@Service
public class CodigoMensagemService {
    private final String servico;
    private final RestClient cliente;
    private final boolean habilitado;

    public CodigoMensagemService(@Value("${auth.twilio.account-sid:}") String conta,
            @Value("${auth.twilio.auth-token:}") String segredo,
            @Value("${auth.twilio.verify-service-sid:}") String servico) {
        this.servico = servico;
        this.habilitado = !conta.isBlank() && !segredo.isBlank() && !servico.isBlank();
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(10000);
        this.cliente = RestClient.builder().requestFactory(factory)
                .baseUrl("https://verify.twilio.com/v2/Services/")
                .defaultHeaders(h -> h.setBasicAuth(conta, segredo)).build();
    }

    public boolean habilitado() { return habilitado; }

    public String enviar(String telefone, String canal) {
        var dados = new LinkedMultiValueMap<String, String>();
        dados.add("To", telefone);
        dados.add("Channel", canal);
        dados.add("Locale", "pt-BR");
        Object sid = executar("Verifications", dados).get("sid");
        if (!(sid instanceof String)) throw indisponivel();
        return (String) sid;
    }

    public boolean verificar(String sid, String codigo) {
        var dados = new LinkedMultiValueMap<String, String>();
        dados.add("VerificationSid", sid);
        dados.add("Code", codigo);
        try {
            return "approved".equals(executar("VerificationCheck", dados).get("status"));
        } catch (ResponseStatusException e) {
            if (e.getStatusCode().value() == 400) return false;
            throw e;
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> executar(String recurso, LinkedMultiValueMap<String, String> dados) {
        if (!habilitado) throw indisponivel();
        try {
            Map<String, Object> resposta = cliente.post().uri(servico + "/" + recurso)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED).body(dados)
                    .retrieve().body(Map.class);
            if (resposta == null) throw indisponivel();
            return resposta;
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            if (e.getStatusCode().value() == 404 || e.getStatusCode().value() == 400) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Código inválido ou expirado. Solicite um novo código.");
            }
            if (e.getStatusCode().value() == 429) {
                throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                        "Aguarde alguns minutos antes de tentar novamente.");
            }
            throw indisponivel();
        } catch (RestClientException e) { throw indisponivel(); }
    }

    private ResponseStatusException indisponivel() {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "O envio de códigos está indisponível. Entre com e-mail e senha ou tente mais tarde.");
    }
}
