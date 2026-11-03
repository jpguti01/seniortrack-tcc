package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.ChamadoSosResponse;
import br.com.tcc.monitoramento.model.ChamadoSos;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.SosService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// Botao SOS: o paciente pede ajuda; o cuidador ve e marca como atendido.
@RestController
@RequestMapping("/sos")
public class SosController {

    private final SosService sosService;
    private final AutorizacaoService autorizacaoService;

    public SosController(SosService sosService, AutorizacaoService autorizacaoService) {
        this.sosService = sosService;
        this.autorizacaoService = autorizacaoService;
    }

    // O paciente vem sempre do token JWT, nunca do corpo da requisicao.
    @PostMapping
    public ResponseEntity<ChamadoSosResponse> acionar(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.PACIENTE) {
            throw new AccessDeniedException("Apenas o paciente pode acionar o SOS.");
        }
        ChamadoSos chamado = sosService.acionar(usuario.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(new ChamadoSosResponse(chamado));
    }

    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<ChamadoSosResponse>> listar(@PathVariable Long pacienteId,
                                                           @RequestParam(defaultValue = "30") int dias,
                                                           @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        int periodo = Math.max(1, Math.min(dias, 365));
        return ResponseEntity.ok(sosService.listarRecentes(pacienteId, periodo).stream()
                .map(ChamadoSosResponse::new).toList());
    }

    @PutMapping("/{id}/atender")
    public ResponseEntity<ChamadoSosResponse> atender(@PathVariable Long id,
                                                      @AuthenticationPrincipal UsuarioAutenticado usuario) {
        ChamadoSos chamado = sosService.buscarPorId(id);
        autorizacaoService.garantirCuidadorDoPaciente(chamado.getPaciente().getId(), usuario);
        return ResponseEntity.ok(new ChamadoSosResponse(sosService.atender(chamado)));
    }
}
