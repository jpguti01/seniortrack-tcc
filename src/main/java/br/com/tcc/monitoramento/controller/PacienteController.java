package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.service.PacienteService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/pacientes")

public class PacienteController {

    private final PacienteService pacienteService;

    public PacienteController(PacienteService pacienteService){
        this.pacienteService = pacienteService;
    }

    // O cadastro de pacientes acontece em POST /auth/cadastro/paciente (AuthController),
    // unico fluxo que define a senha com hash. Este controller so le/gerencia dados.

    @GetMapping
    public ResponseEntity<List<Paciente>> listar() {
        List<Paciente> listaPaciente = pacienteService.listar();
        return ResponseEntity.ok(listaPaciente);
}

    @GetMapping("/{id}")
    public ResponseEntity<Paciente> buscarPorId(@PathVariable Long id) {
        Paciente paciente = pacienteService.buscarPorId(id);
        if (paciente == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(paciente);
    }

    // Endpoint DELETE: Remover um paciente
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        pacienteService.excluir(id);
        return ResponseEntity.noContent().build();
    }

    }