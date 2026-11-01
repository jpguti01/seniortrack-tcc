package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.service.CuidadorService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("/cuidador")

public class CuidadorController {

    private final CuidadorService cuidadorService;

    public CuidadorController(CuidadorService cuidadorService){
        this.cuidadorService = cuidadorService;
    }

    // O cadastro de cuidadores acontece em POST /auth/cadastro/cuidador (AuthController),
    // unico fluxo que define a senha com hash.

    // RF09: o app Flutter chama este endpoint apos obter/renovar o token FCM do dispositivo.
    @PutMapping("/{id}/token-fcm")
    public ResponseEntity<Void> atualizarTokenFcm(@PathVariable Long id, @RequestBody String tokenFcm) {
        Cuidador cuidador = cuidadorService.buscarPorId(id);
        if (cuidador == null) {
            return ResponseEntity.notFound().build();
        }
        cuidador.setTokenFcm(tokenFcm);
        cuidadorService.salvar(cuidador);
        return ResponseEntity.noContent().build();
    }


    @GetMapping
    public ResponseEntity<List<Cuidador>> listar(){
        List<Cuidador> listaCuidador = cuidadorService.listar();
        return ResponseEntity.ok(listaCuidador);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Cuidador> buscarPorId(@PathVariable Long id) {
        Cuidador cuidador = cuidadorService.buscarPorId(id);
        if (cuidador == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(cuidador);
    }
}
