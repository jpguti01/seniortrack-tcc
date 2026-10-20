package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import org.springframework.stereotype.Service;

@Service
public class RegistroSinalVitalService {

    private final RegistroSinalVitalRepository registroSinalVitalRepository;
    private final PacienteRepository pacienteRepository;


    public RegistroSinalVitalService(RegistroSinalVitalRepository registroSinalVitalRepository, PacienteRepository pacienteRepository) {
        this.registroSinalVitalRepository = registroSinalVitalRepository;
        this.pacienteRepository = pacienteRepository;
    }


    public RegistroSinalVital salvar(RegistroSinalVital registroSinalVital){

        if (registroSinalVital.getPaciente() == null)
            throw new RuntimeException("Paciente não encontrado, ou não cadastrado");

        return registroSinalVitalRepository.save(registroSinalVital);

    }
}
