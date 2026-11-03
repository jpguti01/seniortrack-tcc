package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.dto.AdesaoResponse;
import br.com.tcc.monitoramento.dto.DoseResponse;
import br.com.tcc.monitoramento.dto.MedicamentoRequest;
import br.com.tcc.monitoramento.dto.MedicamentoResponse;
import br.com.tcc.monitoramento.model.Medicamento;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.model.TomadaMedicamento;
import br.com.tcc.monitoramento.repository.MedicamentoRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.TomadaMedicamentoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/**
 * Rotina de remedios: o cuidador cadastra, o paciente confirma cada dose e,
 * se uma dose fica 30 minutos sem confirmacao, o cuidador e' avisado.
 */
@Service
public class MedicamentoService {

    public enum StatusDose {
        TOMADO, PENDENTE, ATRASADO
    }

    public static final int TOLERANCIA_MINUTOS = 30;
    // Depois de um tempo sem o servidor rodar, doses antigas sao marcadas sem
    // disparar uma rajada de avisos atrasados para o cuidador.
    private static final int JANELA_AVISO_HORAS = 2;
    private static final int TAMANHO_MAXIMO_FOTO = 1_500_000;

    private static final Logger log = LoggerFactory.getLogger(MedicamentoService.class);

    private final MedicamentoRepository medicamentoRepository;
    private final TomadaMedicamentoRepository tomadaRepository;
    private final PacienteRepository pacienteRepository;
    private final NotificacaoService notificacaoService;

    public MedicamentoService(MedicamentoRepository medicamentoRepository,
                              TomadaMedicamentoRepository tomadaRepository,
                              PacienteRepository pacienteRepository,
                              NotificacaoService notificacaoService) {
        this.medicamentoRepository = medicamentoRepository;
        this.tomadaRepository = tomadaRepository;
        this.pacienteRepository = pacienteRepository;
        this.notificacaoService = notificacaoService;
    }

    public static StatusDose statusDaDose(LocalDateTime previsto, TomadaMedicamento tomada, LocalDateTime agora) {
        if (tomada != null && tomada.getStatus() == TomadaMedicamento.Status.TOMADO) {
            return StatusDose.TOMADO;
        }
        return agora.isBefore(previsto.plusMinutes(TOLERANCIA_MINUTOS)) ? StatusDose.PENDENTE : StatusDose.ATRASADO;
    }

    public List<Medicamento> listarAtivos(Long pacienteId) {
        return medicamentoRepository.findByPaciente_IdAndAtivoTrueOrderByNomeAsc(pacienteId);
    }

    public Medicamento buscarPorId(Long id) {
        return medicamentoRepository.findById(id)
                .orElseThrow(() -> new NegocioException("Remédio não encontrado."));
    }

    public Medicamento criar(Long pacienteId, MedicamentoRequest dados) {
        Paciente paciente = pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new NegocioException("Paciente não encontrado."));
        Medicamento medicamento = new Medicamento(paciente);
        preencher(medicamento, dados);
        return medicamentoRepository.save(medicamento);
    }

    public Medicamento atualizar(Medicamento medicamento, MedicamentoRequest dados) {
        if (!medicamento.isAtivo()) {
            throw new NegocioException("Este remédio foi removido da rotina.");
        }
        preencher(medicamento, dados);
        return medicamentoRepository.save(medicamento);
    }

    public void desativar(Medicamento medicamento) {
        if (medicamento.isAtivo()) {
            medicamento.desativar();
            medicamentoRepository.save(medicamento);
        }
    }

    public List<DoseResponse> dosesDoDia(Long pacienteId, LocalDate dia, LocalDateTime agora) {
        Map<String, TomadaMedicamento> tomadas = tomadasPorDose(pacienteId, dia, dia);
        List<DoseResponse> doses = new ArrayList<>();
        for (Medicamento medicamento : listarAtivos(pacienteId)) {
            for (LocalTime horario : medicamento.getHorarios()) {
                LocalDateTime previsto = dia.atTime(horario);
                if (!medicamento.vigenteEm(previsto)) continue;
                TomadaMedicamento tomada = tomadas.get(chave(medicamento.getId(), dia, horario));
                doses.add(dose(medicamento, dia, horario, statusDaDose(previsto, tomada, agora), tomada));
            }
        }
        doses.sort(Comparator.comparing(DoseResponse::horario).thenComparing(DoseResponse::nome));
        return doses;
    }

    public DoseResponse confirmarTomada(Medicamento medicamento, String horarioTexto, LocalDateTime agora) {
        LocalTime horario = converterHorario(horarioTexto);
        if (!medicamento.isAtivo() || !medicamento.getHorarios().contains(horario)) {
            throw new NegocioException("Este horário não faz parte da rotina deste remédio.");
        }
        LocalDate dia = agora.toLocalDate();
        TomadaMedicamento tomada = tomadaRepository
                .findByMedicamento_IdAndDataAndHorario(medicamento.getId(), dia, horario)
                .orElseGet(() -> new TomadaMedicamento(medicamento, dia, horario, TomadaMedicamento.Status.TOMADO));
        tomada.confirmar(agora);
        tomadaRepository.save(tomada);
        return dose(medicamento, dia, horario, StatusDose.TOMADO, tomada);
    }

    public List<AdesaoResponse> adesao(Long pacienteId, LocalDate desde, LocalDate ate, LocalDateTime agora) {
        Map<String, TomadaMedicamento> tomadas = tomadasPorDose(pacienteId, desde, ate);
        List<AdesaoResponse> resultado = new ArrayList<>();
        for (Medicamento medicamento : medicamentoRepository.findByPaciente_IdOrderByNomeAsc(pacienteId)) {
            int previstas = 0;
            int tomadasNoPeriodo = 0;
            for (LocalDate dia = desde; !dia.isAfter(ate); dia = dia.plusDays(1)) {
                for (LocalTime horario : medicamento.getHorarios()) {
                    LocalDateTime previsto = dia.atTime(horario);
                    if (!medicamento.vigenteEm(previsto)) continue;
                    StatusDose status = statusDaDose(previsto, tomadas.get(chave(medicamento.getId(), dia, horario)), agora);
                    // Uma dose ainda dentro do prazo so conta se ja foi confirmada.
                    if (status == StatusDose.PENDENTE) continue;
                    previstas++;
                    if (status == StatusDose.TOMADO) tomadasNoPeriodo++;
                }
            }
            if (previstas > 0 || medicamento.isAtivo()) {
                resultado.add(new AdesaoResponse(medicamento.getId(), medicamento.getNome(), medicamento.getDosagem(),
                        medicamento.isAtivo(), previstas, tomadasNoPeriodo));
            }
        }
        return resultado;
    }

    @Scheduled(fixedDelay = 60_000, initialDelay = 30_000)
    public void verificarDosesAtrasadas() {
        try {
            verificarDosesAtrasadas(LocalDateTime.now());
        } catch (Exception e) {
            log.error("Falha na verificação de doses atrasadas.", e);
        }
    }

    void verificarDosesAtrasadas(LocalDateTime agora) {
        for (Medicamento medicamento : medicamentoRepository.findByAtivoTrue()) {
            // Ontem tambem, para a dose das 23:50 que so vence depois da meia-noite.
            for (LocalDate dia : List.of(agora.toLocalDate().minusDays(1), agora.toLocalDate())) {
                for (LocalTime horario : medicamento.getHorarios()) {
                    LocalDateTime previsto = dia.atTime(horario);
                    LocalDateTime prazo = previsto.plusMinutes(TOLERANCIA_MINUTOS);
                    if (!medicamento.vigenteEm(previsto) || agora.isBefore(prazo)) continue;
                    if (tomadaRepository.findByMedicamento_IdAndDataAndHorario(medicamento.getId(), dia, horario).isPresent()) {
                        continue;
                    }
                    TomadaMedicamento atrasada = new TomadaMedicamento(medicamento, dia, horario,
                            TomadaMedicamento.Status.ATRASADO);
                    if (agora.isBefore(prazo.plusHours(JANELA_AVISO_HORAS))) {
                        avisarDoseAtrasada(medicamento, horario);
                        atrasada.setCuidadorAvisadoEm(agora);
                    }
                    tomadaRepository.save(atrasada);
                }
            }
        }
    }

    private void avisarDoseAtrasada(Medicamento medicamento, LocalTime horario) {
        Paciente paciente = medicamento.getPaciente();
        String remedio = medicamento.getNome()
                + (medicamento.getDosagem() == null || medicamento.getDosagem().isBlank() ? "" : " " + medicamento.getDosagem());
        notificacaoService.notificarCuidador(paciente.getCuidador(), "💊 Remédio não confirmado",
                paciente.getNome() + " ainda não confirmou a dose de " + remedio + " das "
                        + MedicamentoResponse.HORA.format(horario) + ".",
                true);
    }

    private void preencher(Medicamento medicamento, MedicamentoRequest dados) {
        medicamento.setNome(dados.nome().trim());
        medicamento.setDosagem(textoOpcional(dados.dosagem()));
        medicamento.setInstrucoes(textoOpcional(dados.instrucoes()));
        TreeSet<LocalTime> horarios = new TreeSet<>();
        for (String horario : dados.horarios()) {
            horarios.add(converterHorario(horario));
        }
        medicamento.setHorarios(new ArrayList<>(horarios));
        medicamento.setFoto(validarFoto(dados.foto()));
    }

    private static String validarFoto(String foto) {
        if (foto == null || foto.isBlank()) return null;
        if (foto.length() > TAMANHO_MAXIMO_FOTO) {
            throw new NegocioException("A foto é muito grande. Use uma imagem menor.");
        }
        int virgula = foto.indexOf(',');
        String prefixo = virgula < 0 ? "" : foto.substring(0, virgula);
        if (!prefixo.matches("data:image/(png|jpeg|webp);base64")) {
            throw new NegocioException("Envie a foto em PNG, JPEG ou WEBP.");
        }
        try {
            Base64.getDecoder().decode(foto.substring(virgula + 1));
        } catch (IllegalArgumentException e) {
            throw new NegocioException("A foto enviada está corrompida.");
        }
        return foto;
    }

    private static LocalTime converterHorario(String horario) {
        try {
            return LocalTime.parse(horario == null ? "" : horario.trim()).withSecond(0).withNano(0);
        } catch (DateTimeParseException e) {
            throw new NegocioException("Horário inválido: use o formato HH:mm, por exemplo 08:00.");
        }
    }

    private static String textoOpcional(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim();
    }

    private Map<String, TomadaMedicamento> tomadasPorDose(Long pacienteId, LocalDate desde, LocalDate ate) {
        Map<String, TomadaMedicamento> mapa = new HashMap<>();
        for (TomadaMedicamento tomada : tomadaRepository.findByMedicamento_Paciente_IdAndDataBetween(pacienteId, desde, ate)) {
            mapa.put(chave(tomada.getMedicamento().getId(), tomada.getData(), tomada.getHorario()), tomada);
        }
        return mapa;
    }

    private static String chave(Long medicamentoId, LocalDate dia, LocalTime horario) {
        return medicamentoId + "|" + dia + "|" + horario;
    }

    private static DoseResponse dose(Medicamento medicamento, LocalDate dia, LocalTime horario, StatusDose status,
                                     TomadaMedicamento tomada) {
        return new DoseResponse(medicamento.getId(), medicamento.getNome(), medicamento.getDosagem(),
                medicamento.getInstrucoes(), dia, MedicamentoResponse.HORA.format(horario), status.name(),
                tomada == null ? null : tomada.getConfirmadaEm());
    }
}
