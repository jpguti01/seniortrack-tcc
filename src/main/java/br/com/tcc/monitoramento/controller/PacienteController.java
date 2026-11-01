package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.PacienteService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/pacientes")

public class PacienteController {

    private final PacienteService pacienteService;
    private final AutorizacaoService autorizacaoService;

    public PacienteController(PacienteService pacienteService, AutorizacaoService autorizacaoService){
        this.pacienteService = pacienteService;
        this.autorizacaoService = autorizacaoService;
    }

    // O cadastro de pacientes acontece em POST /auth/cadastro/paciente (AuthController),
    // unico fluxo que define a senha com hash. Este controller so le/gerencia dados.

    // RNF05: so os pacientes vinculados ao cuidador autenticado (nunca todos do sistema).
    @GetMapping
    public ResponseEntity<List<Paciente>> listar(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.CUIDADOR) {
            throw new AccessDeniedException("Apenas cuidadores podem listar pacientes.");
        }
        return ResponseEntity.ok(pacienteService.listarPorCuidador(usuario.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Paciente> buscarPorId(@PathVariable Long id,
                                                 @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(id, usuario);
        Paciente paciente = pacienteService.buscarPorId(id);
        if (paciente == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(paciente);
    }

    // Um paciente so pode excluir a propria conta.
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id,
                                         @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirProprioPaciente(id, usuario);
        pacienteService.excluir(id);
        return ResponseEntity.noContent().build();
    }

}
