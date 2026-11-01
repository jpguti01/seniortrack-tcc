package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.model.RegistroSinalVital.TipoSinalVital;
import br.com.tcc.monitoramento.service.RegistroSinalVitalService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/registrosinalvital")
public class RegistroSinalVitalController {

    private final RegistroSinalVitalService registroSinalVitalService;

    public RegistroSinalVitalController(RegistroSinalVitalService registroSinalVitalService) {
        this.registroSinalVitalService = registroSinalVitalService;
    }

    @PostMapping
    public ResponseEntity<RegistroSinalVital> salvar(@RequestBody RegistroSinalVital registroSinalVital) {
        RegistroSinalVital novoRegistroSinalVital = registroSinalVitalService.salvar(registroSinalVital);
        return ResponseEntity.status(HttpStatus.CREATED).body(novoRegistroSinalVital);
    }

    // RF10/RF11: historico do paciente, com filtro opcional por tipo de sinal ou por periodo.
    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<RegistroSinalVital>> listarPorPaciente(
            @PathVariable Long pacienteId,
            @RequestParam(required = false) TipoSinalVital tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime ate) {

        List<RegistroSinalVital> registros = registroSinalVitalService.filtrarPorPaciente(pacienteId, tipo, desde, ate);
        return ResponseEntity.ok(registros);
    }

    // RF07: corrige o valor do ultimo lancamento do paciente.
    @PutMapping("/paciente/{pacienteId}/ultimo")
    public ResponseEntity<RegistroSinalVital> editarUltimo(@PathVariable Long pacienteId,
                                                             @RequestBody Map<String, Double> corpo) {
        Double novoValor = corpo.get("valorSinalVital");
        if (novoValor == null) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(registroSinalVitalService.editarUltimo(pacienteId, novoValor));
    }

    // RF07: exclui o ultimo lancamento do paciente.
    @DeleteMapping("/paciente/{pacienteId}/ultimo")
    public ResponseEntity<Void> excluirUltimo(@PathVariable Long pacienteId) {
        registroSinalVitalService.excluirUltimo(pacienteId);
        return ResponseEntity.noContent().build();
    }
}
