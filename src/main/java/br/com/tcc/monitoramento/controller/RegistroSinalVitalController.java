package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import br.com.tcc.monitoramento.service.RegistroSinalVitalService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/registrosinalvital")
public class RegistroSinalVitalController {

    private final RegistroSinalVitalService registroSinalVitalService;

    public RegistroSinalVitalController(RegistroSinalVitalService registroSinalVitalService) {
        this.registroSinalVitalService = registroSinalVitalService;
    }

    @PostMapping
    public ResponseEntity<RegistroSinalVital> salvar(@RequestBody RegistroSinalVital registroSinalVital) {
        RegistroSinalVital novoRegistroSinalVital = registroSinalVitalService.salvar(registroSinalVital);
        return ResponseEntity.status(HttpStatus.CREATED).body(novoRegistroSinalVital);
    }
}
