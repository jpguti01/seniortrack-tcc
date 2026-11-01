package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Alerta;
import br.com.tcc.monitoramento.repository.AlertaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AlertaService {

    private final AlertaRepository alertaRepository;

    public AlertaService(AlertaRepository alertaRepository) {
        this.alertaRepository = alertaRepository;
    }

    // RF10: historico de alertas do paciente, mais recente primeiro.
    public List<Alerta> listarPorPaciente(Long pacienteId) {
        return alertaRepository.findByRegistroSinalVital_Paciente_IdOrderByDataHoraDesc(pacienteId);
    }

    public Alerta buscarPorId(Long id) {
        return alertaRepository.findById(id)
                .orElseThrow(() -> new NegocioException("Alerta não encontrado."));
    }

    public Alerta marcarComoResolvido(Alerta alerta) {
        alerta.setResolvido(true);
        return alertaRepository.save(alerta);
    }
}
