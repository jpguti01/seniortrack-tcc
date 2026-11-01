package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.stereotype.Service;

import java.util.List;

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
            throw new NegocioException("O paciente é obrigatório.");
        }

        if (limiarSeguranca.getCuidador() == null){
            throw new NegocioException("O cuidador é obrigatório.");
        }

        // UC-04, fluxo alternativo A1: o minimo nao pode ser igual ou maior que o maximo.
        if (limiarSeguranca.getValorMin() >= limiarSeguranca.getValorMax()) {
            throw new NegocioException("O valor mínimo deve ser menor que o valor máximo.");
        }

        return limiarSegurancaRepository.save(limiarSeguranca);
    }


    public void excluir(LimiarSeguranca limiarSeguranca){
        limiarSegurancaRepository.delete(limiarSeguranca);
    }

    // RF08: lista os limiares configurados de um paciente (usado no dashboard do cuidador).
    public List<LimiarSeguranca> listarPorPaciente(Long pacienteId) {
        return limiarSegurancaRepository.findByPacienteId(pacienteId);
    }



}
