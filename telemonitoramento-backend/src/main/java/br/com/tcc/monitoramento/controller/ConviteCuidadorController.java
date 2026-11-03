package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.security.*;
import br.com.tcc.monitoramento.service.ConviteCuidadorService;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/convites")
public class ConviteCuidadorController {
    private final ConviteCuidadorService convites;
    public ConviteCuidadorController(ConviteCuidadorService convites) { this.convites = convites; }
    @PostMapping
    public Map<String, Object> gerar(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.PACIENTE) throw new AccessDeniedException("Apenas o paciente pode convidar um cuidador.");
        return Map.of("codigo", convites.gerar(usuario.getId()), "validadeHoras", 24);
    }
}
