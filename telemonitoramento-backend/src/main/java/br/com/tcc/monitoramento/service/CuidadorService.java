package br.com.tcc.monitoramento.service;


import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CuidadorService {
    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;

    public CuidadorService(CuidadorRepository cuidadorRepository, PasswordEncoder passwordEncoder) {
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
    }

    // RF01: cadastra um novo cuidador, aplicando o hash BCrypt na senha (RNF01)
    // e recusando e-mails ja cadastrados.
    public Cuidador cadastrar(Cuidador cuidador, String senhaPura) {
        if (cuidadorRepository.existsByEmail(cuidador.getEmail())) {
            throw new IllegalArgumentException("Ja existe um cadastro com este e-mail.");
        }
        cuidador.setSenhaHash(passwordEncoder.encode(senhaPura));
        return cuidadorRepository.save(cuidador);
    }

    //gera um cuidador no banco
    public Cuidador salvar(Cuidador cuidador){
        return cuidadorRepository.save(cuidador);
    }


    //Lista todos os cuidador
    public List<Cuidador> listar(){
        return cuidadorRepository.findAll();
    }

    public Cuidador buscarPorId(Long id){
        return cuidadorRepository.findById(id).orElse(null);
    }

    public void excluir(Long id) {
        cuidadorRepository.deleteById(id);
    }

}
