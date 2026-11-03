package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.AdesaoResponse;
import br.com.tcc.monitoramento.dto.DoseResponse;
import br.com.tcc.monitoramento.dto.MedicamentoRequest;
import br.com.tcc.monitoramento.dto.MedicamentoResponse;
import br.com.tcc.monitoramento.model.Medicamento;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.MedicamentoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

// Rotina de remedios: o cuidador vinculado cadastra e edita; o proprio
// paciente confirma as doses; ambos consultam a rotina e a adesao.
@RestController
@RequestMapping("/medicamentos")
public class MedicamentoController {

    private final MedicamentoService medicamentoService;
    private final AutorizacaoService autorizacaoService;

    public MedicamentoController(MedicamentoService medicamentoService, AutorizacaoService autorizacaoService) {
        this.medicamentoService = medicamentoService;
        this.autorizacaoService = autorizacaoService;
    }

    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<MedicamentoResponse>> listar(@PathVariable Long pacienteId,
                                                            @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        return ResponseEntity.ok(medicamentoService.listarAtivos(pacienteId).stream()
                .map(MedicamentoResponse::new).toList());
    }

    @PostMapping("/paciente/{pacienteId}")
    public ResponseEntity<MedicamentoResponse> criar(@PathVariable Long pacienteId,
                                                     @Valid @RequestBody MedicamentoRequest dados,
                                                     @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirCuidadorDoPaciente(pacienteId, usuario);
        Medicamento medicamento = medicamentoService.criar(pacienteId, dados);
        return ResponseEntity.status(HttpStatus.CREATED).body(new MedicamentoResponse(medicamento));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MedicamentoResponse> atualizar(@PathVariable Long id,
                                                         @Valid @RequestBody MedicamentoRequest dados,
                                                         @AuthenticationPrincipal UsuarioAutenticado usuario) {
        Medicamento medicamento = medicamentoService.buscarPorId(id);
        autorizacaoService.garantirCuidadorDoPaciente(medicamento.getPaciente().getId(), usuario);
        return ResponseEntity.ok(new MedicamentoResponse(medicamentoService.atualizar(medicamento, dados)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long id,
                                        @AuthenticationPrincipal UsuarioAutenticado usuario) {
        Medicamento medicamento = medicamentoService.buscarPorId(id);
        autorizacaoService.garantirCuidadorDoPaciente(medicamento.getPaciente().getId(), usuario);
        medicamentoService.desativar(medicamento);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/paciente/{pacienteId}/hoje")
    public ResponseEntity<List<DoseResponse>> dosesDeHoje(@PathVariable Long pacienteId,
                                                          @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        LocalDateTime agora = LocalDateTime.now();
        return ResponseEntity.ok(medicamentoService.dosesDoDia(pacienteId, agora.toLocalDate(), agora));
    }

    // Somente o proprio paciente marca "Tomei"; o dia e o horario da confirmacao vem do servidor.
    @PostMapping("/{id}/tomadas")
    public ResponseEntity<DoseResponse> confirmarTomada(@PathVariable Long id,
                                                        @RequestBody Map<String, String> corpo,
                                                        @AuthenticationPrincipal UsuarioAutenticado usuario) {
        Medicamento medicamento = medicamentoService.buscarPorId(id);
        autorizacaoService.garantirProprioPaciente(medicamento.getPaciente().getId(), usuario);
        return ResponseEntity.ok(medicamentoService.confirmarTomada(medicamento, corpo.get("horario"), LocalDateTime.now()));
    }

    @GetMapping("/paciente/{pacienteId}/adesao")
    public ResponseEntity<List<AdesaoResponse>> adesao(@PathVariable Long pacienteId,
                                                       @RequestParam(defaultValue = "30") int dias,
                                                       @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        int periodo = Math.max(1, Math.min(dias, 365));
        LocalDateTime agora = LocalDateTime.now();
        LocalDate hoje = agora.toLocalDate();
        return ResponseEntity.ok(medicamentoService.adesao(pacienteId, hoje.minusDays(periodo - 1L), hoje, agora));
    }
}
