package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.CheckinBemEstar;
import br.com.tcc.monitoramento.model.CheckinBemEstar.Humor;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.CheckinBemEstarRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class BemEstarService {

    private final CheckinBemEstarRepository checkinRepository;
    private final PacienteRepository pacienteRepository;
    private final NotificacaoService notificacaoService;

    public BemEstarService(CheckinBemEstarRepository checkinRepository, PacienteRepository pacienteRepository,
                           NotificacaoService notificacaoService) {
        this.checkinRepository = checkinRepository;
        this.pacienteRepository = pacienteRepository;
        this.notificacaoService = notificacaoService;
    }

    // Um check-in por dia. "Com dor" ou "Mal" avisa o cuidador por push, mas
    // so quando a resposta do dia passa a ser preocupante (sem repetir o aviso
    // se o paciente apenas reenviar a mesma resposta).
    public CheckinBemEstar registrar(Long pacienteId, Humor humor, String observacao, LocalDateTime agora) {
        if (humor == null) {
            throw new NegocioException("Escolha como você está se sentindo.");
        }
        String texto = observacao == null || observacao.isBlank() ? null : observacao.trim();
        if (texto != null && texto.length() > 255) {
            throw new NegocioException("A observação deve ter no máximo 255 caracteres.");
        }
        LocalDate hoje = agora.toLocalDate();
        Optional<CheckinBemEstar> existente = checkinRepository.findByPaciente_IdAndData(pacienteId, hoje);
        boolean jaEraPreocupante = existente.map(c -> c.getHumor().preocupante()).orElse(false);

        CheckinBemEstar checkin = existente.orElseGet(() -> new CheckinBemEstar(buscarPaciente(pacienteId), hoje));
        checkin.responder(humor, texto, agora);
        checkinRepository.save(checkin);

        if (humor.preocupante() && !jaEraPreocupante) {
            Paciente paciente = checkin.getPaciente();
            String sentimento = humor == Humor.MAL ? "está se sentindo mal" : "está com dor";
            notificacaoService.notificarCuidador(paciente.getCuidador(), "Check-in de bem-estar",
                    paciente.getNome() + " informou que " + sentimento + " hoje."
                            + (texto == null ? "" : " Observação: " + texto),
                    false);
        }
        return checkin;
    }

    public Optional<CheckinBemEstar> doDia(Long pacienteId, LocalDate dia) {
        return checkinRepository.findByPaciente_IdAndData(pacienteId, dia);
    }

    public List<CheckinBemEstar> listarRecentes(Long pacienteId, int dias, LocalDate hoje) {
        return checkinRepository.findByPaciente_IdAndDataGreaterThanEqualOrderByDataDesc(pacienteId,
                hoje.minusDays(dias - 1L));
    }

    private Paciente buscarPaciente(Long pacienteId) {
        return pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new NegocioException("Paciente não encontrado."));
    }
}
