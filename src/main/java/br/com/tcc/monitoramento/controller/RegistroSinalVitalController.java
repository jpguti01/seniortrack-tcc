package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.model.RegistroSinalVital.TipoSinalVital;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.RegistroSinalVitalService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/registrosinalvital")
public class RegistroSinalVitalController {

    private final RegistroSinalVitalService registroSinalVitalService;
    private final AutorizacaoService autorizacaoService;

    public RegistroSinalVitalController(RegistroSinalVitalService registroSinalVitalService,
                                         AutorizacaoService autorizacaoService) {
        this.registroSinalVitalService = registroSinalVitalService;
        this.autorizacaoService = autorizacaoService;
    }

    // UC-02: so o proprio paciente registra o seu sinal vital. O dono do registro
    // vem sempre do token JWT, nunca do corpo da requisicao (evita que um campo
    // "paciente" forjado grave o dado em nome de outra pessoa), e o id e' sempre
    // ignorado para garantir que isto so cria um registro novo, nunca sobrescreve um existente.
    @PostMapping
    public ResponseEntity<RegistroSinalVital> salvar(@RequestBody RegistroSinalVital registroSinalVital,
                                                       @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.PACIENTE) {
            throw new AccessDeniedException("Apenas o paciente pode registrar o próprio sinal vital.");
        }

        Paciente referenciaPaciente = new Paciente();
        referenciaPaciente.setId(usuario.getId());
        registroSinalVital.setPaciente(referenciaPaciente);
        registroSinalVital.setId(0);

        RegistroSinalVital novoRegistroSinalVital = registroSinalVitalService.salvar(registroSinalVital);
        return ResponseEntity.status(HttpStatus.CREATED).body(novoRegistroSinalVital);
    }

    // RF10/RF11: historico do paciente, com filtro opcional por tipo de sinal ou por periodo.
    // Acessivel pelo proprio paciente ou pelo cuidador vinculado a ele (RNF05).
    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<RegistroSinalVital>> listarPorPaciente(
            @PathVariable Long pacienteId,
            @RequestParam(required = false) TipoSinalVital tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime ate,
            @AuthenticationPrincipal UsuarioAutenticado usuario) {

        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        List<RegistroSinalVital> registros = registroSinalVitalService.filtrarPorPaciente(pacienteId, tipo, desde, ate);
        return ResponseEntity.ok(registros);
    }

    // RF07: corrige o valor do ultimo lancamento - somente o proprio paciente.
    @PutMapping("/paciente/{pacienteId}/ultimo")
    public ResponseEntity<RegistroSinalVital> editarUltimo(@PathVariable Long pacienteId,
                                                             @RequestBody Map<String, Double> corpo,
                                                             @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirProprioPaciente(pacienteId, usuario);
        Double novoValor = corpo.get("valorSinalVital");
        if (novoValor == null) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(registroSinalVitalService.editarUltimo(pacienteId, novoValor));
    }

    // RF07: exclui o ultimo lancamento - somente o proprio paciente.
    @DeleteMapping("/paciente/{pacienteId}/ultimo")
    public ResponseEntity<Void> excluirUltimo(@PathVariable Long pacienteId,
                                               @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirProprioPaciente(pacienteId, usuario);
        registroSinalVitalService.excluirUltimo(pacienteId);
        return ResponseEntity.noContent().build();
    }
}
