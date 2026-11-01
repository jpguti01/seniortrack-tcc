package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PacienteService {

    // 1. Declaramos o repository que será injetado pelo Spring
    private final PacienteRepository pacienteRepository;
    private final PasswordEncoder passwordEncoder;

    // 2. Construtor para Injeção de Dependência (Boa prática no Spring Boot)
    public PacienteService(PacienteRepository pacienteRepository, PasswordEncoder passwordEncoder) {
        this.pacienteRepository = pacienteRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // RF01: cadastra um novo paciente, aplicando o hash BCrypt na senha (RNF01)
    // e recusando e-mails ja cadastrados.
    public Paciente cadastrar(Paciente paciente, String senhaPura) {
        if (pacienteRepository.existsByEmail(paciente.getEmail())) {
            throw new IllegalArgumentException("Ja existe um cadastro com este e-mail.");
        }
        paciente.setSenhaHash(passwordEncoder.encode(senhaPura));
        return pacienteRepository.save(paciente);
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

