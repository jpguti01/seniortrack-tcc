package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.ChamadoSos;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.ChamadoSosRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Botao SOS do paciente: registra o pedido de ajuda e avisa o cuidador como
 * urgencia (push + WhatsApp/SMS/webhook, se configurados). Toques repetidos em
 * ate 2 minutos reaproveitam o mesmo chamado, sem repetir a notificacao.
 */
@Service
public class SosService {

    private static final int JANELA_REPETICAO_MINUTOS = 2;

    private final ChamadoSosRepository chamadoSosRepository;
    private final PacienteRepository pacienteRepository;
    private final NotificacaoService notificacaoService;

    public SosService(ChamadoSosRepository chamadoSosRepository, PacienteRepository pacienteRepository,
                      NotificacaoService notificacaoService) {
        this.chamadoSosRepository = chamadoSosRepository;
        this.pacienteRepository = pacienteRepository;
        this.notificacaoService = notificacaoService;
    }

    public ChamadoSos acionar(Long pacienteId) {
        Optional<ChamadoSos> recente = chamadoSosRepository
                .findFirstByPaciente_IdAndAtendidoFalseAndCriadoEmAfterOrderByCriadoEmDesc(
                        pacienteId, LocalDateTime.now().minusMinutes(JANELA_REPETICAO_MINUTOS));
        if (recente.isPresent()) {
            return recente.get();
        }
        Paciente paciente = pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new NegocioException("Paciente não encontrado."));
        ChamadoSos chamado = chamadoSosRepository.save(new ChamadoSos(paciente));

        String telefone = paciente.getTelefone() == null || paciente.getTelefone().isBlank()
                ? "" : " Telefone: " + paciente.getTelefone() + ".";
        notificacaoService.notificarCuidador(paciente.getCuidador(), "🆘 SOS de " + paciente.getNome(),
                paciente.getNome() + " acionou o botão de emergência no SeniorTrack e pediu ajuda." + telefone,
                true);
        return chamado;
    }

    public List<ChamadoSos> listarRecentes(Long pacienteId, int dias) {
        return chamadoSosRepository.findByPaciente_IdAndCriadoEmAfterOrderByCriadoEmDesc(
                pacienteId, LocalDateTime.now().minusDays(dias));
    }

    public List<ChamadoSos> listarPendentes(Long pacienteId) {
        return chamadoSosRepository.findByPaciente_IdAndAtendidoFalseOrderByCriadoEmDesc(pacienteId);
    }

    public ChamadoSos buscarPorId(Long id) {
        return chamadoSosRepository.findById(id)
                .orElseThrow(() -> new NegocioException("Chamado não encontrado."));
    }

    public ChamadoSos atender(ChamadoSos chamado) {
        if (!chamado.isAtendido()) {
            chamado.marcarAtendido();
            chamadoSosRepository.save(chamado);
        }
        return chamado;
    }
}
