package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.CheckinBemEstarResponse;
import br.com.tcc.monitoramento.model.CheckinBemEstar.Humor;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.BemEstarService;
import br.com.tcc.monitoramento.service.NegocioException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

// Diario de bem-estar: o paciente responde uma vez por dia; o paciente e o
// cuidador vinculado consultam o historico.
@RestController
@RequestMapping("/bemestar")
public class BemEstarController {

    private final BemEstarService bemEstarService;
    private final AutorizacaoService autorizacaoService;

    public BemEstarController(BemEstarService bemEstarService, AutorizacaoService autorizacaoService) {
        this.bemEstarService = bemEstarService;
        this.autorizacaoService = autorizacaoService;
    }

    @PostMapping
    public ResponseEntity<CheckinBemEstarResponse> registrar(@RequestBody Map<String, String> corpo,
                                                             @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.PACIENTE) {
            throw new AccessDeniedException("Apenas o paciente registra o próprio bem-estar.");
        }
        Humor humor;
        try {
            humor = Humor.valueOf(corpo.getOrDefault("humor", ""));
        } catch (IllegalArgumentException e) {
            throw new NegocioException("Escolha como você está se sentindo.");
        }
        var checkin = bemEstarService.registrar(usuario.getId(), humor, corpo.get("observacao"), LocalDateTime.now());
        return ResponseEntity.ok(new CheckinBemEstarResponse(checkin));
    }

    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<CheckinBemEstarResponse>> listar(@PathVariable Long pacienteId,
                                                                @RequestParam(defaultValue = "30") int dias,
                                                                @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        int periodo = Math.max(1, Math.min(dias, 365));
        return ResponseEntity.ok(bemEstarService.listarRecentes(pacienteId, periodo, LocalDate.now()).stream()
                .map(CheckinBemEstarResponse::new).toList());
    }
}
