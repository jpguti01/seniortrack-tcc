package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Medicamento;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.model.TomadaMedicamento;
import br.com.tcc.monitoramento.repository.MedicamentoRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.TomadaMedicamentoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.lang.reflect.Proxy;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.function.BiFunction;

import static br.com.tcc.monitoramento.service.MedicamentoService.StatusDose.*;
import static org.junit.jupiter.api.Assertions.*;

// Sem Mockito: o Mockito do Spring Boot 3.2 nao consegue instrumentar classes no Java 25.
class MedicamentoServiceTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 11, 2);

    static class NotificacaoFalsa extends NotificacaoService {
        final List<String> enviadas = new ArrayList<>();

        NotificacaoFalsa() {
            super(List.of());
        }

        @Override
        public void notificarCuidador(Cuidador cuidador, String titulo, String mensagem, boolean urgente) {
            enviadas.add(titulo + " | " + mensagem + " | urgente=" + urgente);
        }
    }

    @SuppressWarnings("unchecked")
    private static <T> T falso(Class<T> tipo, BiFunction<String, Object[], Object> resposta) {
        return (T) Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo},
                (proxy, metodo, args) -> resposta.apply(metodo.getName(), args));
    }

    private final List<TomadaMedicamento> existentes = new ArrayList<>();
    private final List<TomadaMedicamento> salvas = new ArrayList<>();
    private NotificacaoFalsa notificacao;
    private MedicamentoService service;
    private Medicamento losartana;

    @BeforeEach
    void preparar() throws Exception {
        Paciente paciente = new Paciente("Joao", "joao@teste.invalid", "hash", 70, "(11) 00000-0000");
        paciente.setCuidador(new Cuidador("Ana", "ana@teste.invalid", "hash", 40, "(11) 00000-0000"));
        losartana = new Medicamento(paciente);
        losartana.setNome("Losartana");
        losartana.setDosagem("50 mg");
        losartana.setHorarios(List.of(LocalTime.of(8, 0), LocalTime.of(20, 0)));
        definir(losartana, "criadoEm", HOJE.minusDays(10).atStartOfDay());
        definir(losartana, "id", 7L);

        MedicamentoRepository medicamentos = falso(MedicamentoRepository.class, (metodo, args) -> switch (metodo) {
            case "findByAtivoTrue" -> List.of(losartana);
            default -> throw new AssertionError(metodo);
        });
        TomadaMedicamentoRepository tomadas = falso(TomadaMedicamentoRepository.class, (metodo, args) -> switch (metodo) {
            case "findByMedicamento_IdAndDataAndHorario" -> existentes.stream()
                    .filter(t -> t.getData().equals(args[1]) && t.getHorario().equals(args[2])).findFirst();
            case "save" -> {
                salvas.add((TomadaMedicamento) args[0]);
                yield args[0];
            }
            default -> throw new AssertionError(metodo);
        });
        notificacao = new NotificacaoFalsa();
        service = new MedicamentoService(medicamentos, tomadas,
                falso(PacienteRepository.class, (metodo, args) -> Optional.empty()), notificacao);
    }

    private static void definir(Object alvo, String campo, Object valor) throws Exception {
        Field f = alvo.getClass().getDeclaredField(campo);
        f.setAccessible(true);
        f.set(alvo, valor);
    }

    @Test
    void doseFicaAtrasadaSo30MinutosDepoisDoHorario() {
        LocalDateTime previsto = HOJE.atTime(8, 0);
        assertEquals(PENDENTE, MedicamentoService.statusDaDose(previsto, null, previsto.plusMinutes(29)));
        assertEquals(ATRASADO, MedicamentoService.statusDaDose(previsto, null, previsto.plusMinutes(30)));
        var tomada = new TomadaMedicamento(losartana, HOJE, LocalTime.of(8, 0), TomadaMedicamento.Status.ATRASADO);
        tomada.confirmar(previsto.plusHours(1));
        assertEquals(TOMADO, MedicamentoService.statusDaDose(previsto, tomada, previsto.plusHours(2)));
    }

    @Test
    void avisaOCuidadorUmaVezQuandoADoseNaoEConfirmada() {
        service.verificarDosesAtrasadas(HOJE.atTime(8, 31));

        // Ontem as 08:00 e 20:00 sao registradas sem aviso (fora da janela); hoje as 08:00 venceu agora.
        assertEquals(3, salvas.size());
        var deHoje = salvas.stream().filter(t -> t.getData().equals(HOJE)).toList();
        assertEquals(1, deHoje.size());
        assertEquals(TomadaMedicamento.Status.ATRASADO, deHoje.get(0).getStatus());
        assertNotNull(deHoje.get(0).getCuidadorAvisadoEm());
        assertEquals(1, notificacao.enviadas.size());
        String aviso = notificacao.enviadas.get(0);
        assertTrue(aviso.contains("não confirmado") && aviso.contains("Losartana 50 mg das 08:00"), aviso);
        assertTrue(aviso.endsWith("urgente=true"));
    }

    @Test
    void naoRepeteAvisoDeDoseJaRegistrada() {
        for (LocalDate dia : List.of(HOJE.minusDays(1), HOJE)) {
            for (LocalTime horario : losartana.getHorarios()) {
                existentes.add(new TomadaMedicamento(losartana, dia, horario, TomadaMedicamento.Status.ATRASADO));
            }
        }

        service.verificarDosesAtrasadas(HOJE.atTime(8, 45));

        assertTrue(salvas.isEmpty());
        assertTrue(notificacao.enviadas.isEmpty());
    }

    @Test
    void naoCobraDoseAnteriorAoCadastroDoRemedio() throws Exception {
        definir(losartana, "criadoEm", HOJE.atTime(9, 0));

        service.verificarDosesAtrasadas(HOJE.atTime(10, 0));

        assertTrue(salvas.isEmpty());
    }
}
