package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
public class SessaoController {
    @GetMapping("/sessao")
    public Map<String, Object> verificar(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        return Map.of("id", usuario.getId(), "tipo", usuario.getTipo().name());
    }
}
