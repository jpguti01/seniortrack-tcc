package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.service.LimiarSegurancaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/limiarseguranca")
public class LimiarSegurancaController {

    private final LimiarSegurancaService limiarSegurancaService;

    public LimiarSegurancaController(LimiarSegurancaService limiarSegurancaService){
        this.limiarSegurancaService = limiarSegurancaService;
    }

    @PostMapping
    public ResponseEntity<LimiarSeguranca>salvar(@RequestBody LimiarSeguranca limiarSeguranca){
        LimiarSeguranca novaLimiar =  limiarSegurancaService.salvar(limiarSeguranca);
        return ResponseEntity.status(HttpStatus.CREATED).body(novaLimiar);
    }

    // RF08: lista os limiares configurados de um paciente.
    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<LimiarSeguranca>> listarPorPaciente(@PathVariable Long pacienteId) {
        return ResponseEntity.ok(limiarSegurancaService.listarPorPaciente(pacienteId));
    }
}
