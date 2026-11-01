package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.security.AutorizacaoService;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.LimiarSegurancaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/limiarseguranca")
public class LimiarSegurancaController {

    private final LimiarSegurancaService limiarSegurancaService;
    private final AutorizacaoService autorizacaoService;

    public LimiarSegurancaController(LimiarSegurancaService limiarSegurancaService,
                                      AutorizacaoService autorizacaoService){
        this.limiarSegurancaService = limiarSegurancaService;
        this.autorizacaoService = autorizacaoService;
    }

    // Somente o cuidador vinculado ao paciente pode configurar seus limiares (RF08).
    @PostMapping
    public ResponseEntity<LimiarSeguranca> salvar(@RequestBody LimiarSeguranca limiarSeguranca,
                                                   @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (limiarSeguranca.getPaciente() != null && limiarSeguranca.getPaciente().getId() != null) {
            autorizacaoService.garantirCuidadorDoPaciente(limiarSeguranca.getPaciente().getId(), usuario);
        }
        LimiarSeguranca novaLimiar =  limiarSegurancaService.salvar(limiarSeguranca);
        return ResponseEntity.status(HttpStatus.CREATED).body(novaLimiar);
    }

    // RF08: lista os limiares configurados de um paciente (proprio paciente ou cuidador vinculado).
    @GetMapping("/paciente/{pacienteId}")
    public ResponseEntity<List<LimiarSeguranca>> listarPorPaciente(@PathVariable Long pacienteId,
                                                                     @AuthenticationPrincipal UsuarioAutenticado usuario) {
        autorizacaoService.garantirAcessoAoPaciente(pacienteId, usuario);
        return ResponseEntity.ok(limiarSegurancaService.listarPorPaciente(pacienteId));
    }
}
