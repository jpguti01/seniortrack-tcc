package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.service.CuidadorService;
import org.springframework.http.HttpStatus;
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

    @PostMapping
    public ResponseEntity<Cuidador> salvar(@RequestBody Cuidador cuidador){
        Cuidador novoCuidador = cuidadorService.salvar(cuidador);
        return ResponseEntity.status(HttpStatus.CREATED).body(novoCuidador);
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
