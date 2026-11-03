package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.TokenResponse;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.service.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AcessoAlternativoController {
    private final AcessoAlternativoService acesso;
    private final CodigoMensagemService mensagens;
    public AcessoAlternativoController(AcessoAlternativoService acesso, CodigoMensagemService mensagens) {
        this.acesso = acesso; this.mensagens = mensagens;
    }
    public record Solicitar(@NotBlank String telefone, @NotNull TipoUsuario perfil,
                            @Pattern(regexp = "login|recuperacao") @NotBlank String finalidade,
                            @Pattern(regexp = "sms|whatsapp") @NotBlank String canal) {}
    public record Confirmar(@NotBlank String desafio, @Pattern(regexp = "[0-9]{6}") @NotBlank String codigo) {}
    public record Recuperar(@NotBlank String desafio, @Pattern(regexp = "[0-9]{6}") @NotBlank String codigo,
                            @NotBlank @Size(min = 8, max = 72) String novaSenha) {}
    public record Google(@NotBlank @Size(max = 10000) String idToken, @NotNull TipoUsuario perfil) {}

    @GetMapping("/opcoes")
    public Map<String, Boolean> opcoes() {
        return Map.of("codigo", mensagens.habilitado(), "google", acesso.googleHabilitado());
    }
    @PostMapping("/codigo/solicitar")
    public Map<String, Object> solicitar(@Valid @RequestBody Solicitar r) {
        return Map.of("desafio", acesso.solicitar(r.telefone(), r.perfil(), r.finalidade(), r.canal()),
                "reenviarEm", 60, "expiraEm", 600,
                "mensagem", "Se este celular estiver cadastrado no perfil escolhido, você receberá um código.");
    }
    @PostMapping("/codigo/confirmar")
    public TokenResponse confirmar(@Valid @RequestBody Confirmar r) {
        return acesso.confirmar(r.desafio(), r.codigo(), "login", null);
    }
    @PostMapping("/senha/recuperar")
    public TokenResponse recuperar(@Valid @RequestBody Recuperar r) {
        return acesso.confirmar(r.desafio(), r.codigo(), "recuperacao", r.novaSenha());
    }
    @PostMapping("/google")
    public TokenResponse google(@Valid @RequestBody Google r) { return acesso.google(r.idToken(), r.perfil()); }
}
