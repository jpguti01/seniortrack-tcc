package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import org.springframework.stereotype.Service;

@Service
public class RegistroSinalVitalService {

    private final RegistroSinalVitalRepository registroSinalVitalRepository;

    public RegistroSinalVitalService(RegistroSinalVitalRepository registroSinalVitalRepository) {
        this.registroSinalVitalRepository = registroSinalVitalRepository;
    }


    public RegistroSinalVital salvar(RegistroSinalVital registroSinalVital){
        return registroSinalVitalRepository.save(registroSinalVital);

    }
}
