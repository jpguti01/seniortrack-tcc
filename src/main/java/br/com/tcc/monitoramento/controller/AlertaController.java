package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Alerta;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.AlertaService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// RF10: alertas gerados pelo motor de regras (RF09), exibidos no dashboard do cuidador.
@RestController
@RequestMapping("/alertas")
public class AlertaController {

    private final AlertaService alertaService;
    private final AutorizacaoService autorizacaoService;

    public AlertaController(AlertaService alertaService, AutorizacaoService autorizacaoService) {
        this.alertaService = alertaService;
        this.autorizacaoService = autorizacaoService;
    }

    // Acessivel pelo proprio paciente ou pelo cuidador vinculado a ele (RNF05).
    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<Alerta>> listarPorPaciente(@PathVariable Long pacienteId,
                                                            @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        return ResponseEntity.ok(alertaService.listarPorPaciente(pacienteId));
    }

    // So o cuidador responsavel pelo paciente do alerta pode marca-lo como resolvido.
    @PutMapping("/{id}/resolver")
    public ResponseEntity<Alerta> marcarComoResolvido(@PathVariable Long id,
                                                        @AuthenticationPrincipal UsuarioAutenticado usuario) {
        Alerta alerta = alertaService.buscarPorId(id);
        Long pacienteId = alerta.getRegistroSinalVital().getPaciente().getId();
        autorizacaoService.garantirCuidadorDoPaciente(pacienteId, usuario);
        return ResponseEntity.ok(alertaService.marcarComoResolvido(alerta));
    }
}
