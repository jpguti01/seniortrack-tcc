package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.stereotype.Service;

@Service
public class LimiarSegurancaService {

    private final LimiarSegurancaRepository limiarSegurancaRepository;
    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;

    public LimiarSegurancaService(LimiarSegurancaRepository limiarSegurancaRepository, PacienteRepository pacienteRepository, CuidadorRepository cuidadorRepository) {
        this.limiarSegurancaRepository = limiarSegurancaRepository;
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;

    }

    public LimiarSeguranca salvar(LimiarSeguranca limiarSeguranca) {
        if (limiarSeguranca.getTipoSinalVital() == null){
            throw new IllegalArgumentException("O tipo do sinal vital é obrigatório! ");
        }

        if (limiarSeguranca.getPaciente() == null){
            throw new RuntimeException("Opaciete");

        }

        if (limiarSeguranca.getCuidador() == null){
                throw new RuntimeException( "Sem cuidador");


        }

            return limiarSegurancaRepository.save(limiarSeguranca);
    }


    public void excluir(LimiarSeguranca limiarSeguranca){
        limiarSegurancaRepository.delete(limiarSeguranca);
    }



}
