package br.com.tcc.monitoramento.service;


import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;

@Service
public class CuidadorService {
    private final CuidadorRepository cuidadorRepository;

    public CuidadorService(CuidadorRepository cuidadorRepository) {
        this.cuidadorRepository = cuidadorRepository;
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
