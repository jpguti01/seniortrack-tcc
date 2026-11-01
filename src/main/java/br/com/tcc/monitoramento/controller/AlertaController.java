package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Alerta;
import br.com.tcc.monitoramento.service.AlertaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// RF10: alertas gerados pelo motor de regras (RF09), exibidos no dashboard do cuidador.
@RestController
@RequestMapping("/alertas")
public class AlertaController {

    private final AlertaService alertaService;

    public AlertaController(AlertaService alertaService) {
        this.alertaService = alertaService;
    }

    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<Alerta>> listarPorPaciente(@PathVariable Long pacienteId) {
        return ResponseEntity.ok(alertaService.listarPorPaciente(pacienteId));
    }

    @PutMapping("/{id}/resolver")
    public ResponseEntity<Alerta> marcarComoResolvido(@PathVariable Long id) {
        return ResponseEntity.ok(alertaService.marcarComoResolvido(id));
    }
}
