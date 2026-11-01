package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Cuidador;
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

    // RF08, UC-04: somente o cuidador vinculado ao paciente indicado pode
    // configurar seus limiares. Falha fechado: sem paciente valido no corpo,
    // a requisicao e' rejeitada (nunca segue sem autorizar). O campo "cuidador"
    // e' sempre o usuario autenticado, nunca o que vier no corpo da requisicao
    // (evita que um cuidador atribua o limiar a outro cuidador). O id tambem
    // e' sempre ignorado, para que isto so crie um limiar novo.
    @PostMapping
    public ResponseEntity<?> salvar(@RequestBody LimiarSeguranca limiarSeguranca,
                                     @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (limiarSeguranca.getPaciente() == null || limiarSeguranca.getPaciente().getId() == null) {
            return ResponseEntity.badRequest().body("O paciente é obrigatório.");
        }
        autorizacaoService.garantirCuidadorDoPaciente(limiarSeguranca.getPaciente().getId(), usuario);

        Cuidador referenciaCuidador = new Cuidador();
        referenciaCuidador.setId(usuario.getId());
        limiarSeguranca.setCuidador(referenciaCuidador);
        limiarSeguranca.setId(null);

        LimiarSeguranca novaLimiar = limiarSegurancaService.salvar(limiarSeguranca);
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
