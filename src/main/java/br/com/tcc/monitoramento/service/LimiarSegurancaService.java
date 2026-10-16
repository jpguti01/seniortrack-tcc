package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import org.springframework.stereotype.Service;

@Service
public class LimiarSegurancaService {

    private final LimiarSegurancaRepository limiarSegurancaRepository;

    public LimiarSegurancaService(LimiarSegurancaRepository limiarSegurancaRepository) {
        this.limiarSegurancaRepository = limiarSegurancaRepository;
    }

    public LimiarSeguranca salvar(LimiarSeguranca limiarSeguranca){
        return limiarSegurancaRepository.save(limiarSeguranca);
    }


    public void excluir(LimiarSeguranca limiarSeguranca){
        limiarSegurancaRepository.delete(limiarSeguranca);
    }



}
