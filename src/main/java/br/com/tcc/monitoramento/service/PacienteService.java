package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PacienteService {

    // 1. Declaramos o repository que será injetado pelo Spring
    private final PacienteRepository pacienteRepository;

    // 2. Construtor para Injeção de Dependência (Boa prática no Spring Boot)
    public PacienteService(PacienteRepository pacienteRepository) {

        this.pacienteRepository = pacienteRepository;
    }



    //Salvar ou atualizar o paciente
    public Paciente salvar(Paciente paciente){
        return pacienteRepository.save(paciente);

    }


    public List<Paciente> listar(){
        return pacienteRepository.findAll();
    }


    public Paciente buscarPorId(Long id){
        return pacienteRepository.findById(id).orElse(null);
    }

    public void excluir(Long id){
        pacienteRepository.deleteById(id);
    }

}

