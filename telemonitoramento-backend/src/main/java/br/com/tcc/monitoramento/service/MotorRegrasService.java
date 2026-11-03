package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Alerta;
import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Gravidade;
import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.AlertaRepository;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;

// RF09, UC-03: avalia um sinal vital recem-registrado contra o limiar
// configurado pelo cuidador e, se estiver fora da faixa, gera um alerta
// persistido (com gravidade) e avisa o cuidador (RNF03: em ate 2 segundos).
// Alertas criticos ou persistentes (fora da faixa tambem no dia anterior)
// sao urgencias e tambem saem pelos canais externos (WhatsApp/SMS/webhook).
@Service
public class MotorRegrasService {

    private static final Logger log = LoggerFactory.getLogger(MotorRegrasService.class);
    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");

    private final LimiarSegurancaRepository limiarSegurancaRepository;
    private final AlertaRepository alertaRepository;
    private final RegistroSinalVitalRepository registroSinalVitalRepository;
    private final NotificacaoService notificacaoService;

    public MotorRegrasService(LimiarSegurancaRepository limiarSegurancaRepository,
                               AlertaRepository alertaRepository,
                               RegistroSinalVitalRepository registroSinalVitalRepository,
                               NotificacaoService notificacaoService) {
        this.limiarSegurancaRepository = limiarSegurancaRepository;
        this.alertaRepository = alertaRepository;
        this.registroSinalVitalRepository = registroSinalVitalRepository;
        this.notificacaoService = notificacaoService;
    }

    public void analisarRegistro(RegistroSinalVital registro) {
        Long pacienteId = registro.getPaciente().getId();

        Optional<LimiarSeguranca> limiarOpt = limiarSegurancaRepository
                .findByPacienteIdAndTipoSinalVital(pacienteId, registro.getTipoSinalVital());

        if (limiarOpt.isEmpty()) {
            // Sem limiar configurado para este tipo de sinal ainda (RF08 nao foi feito pelo
            // cuidador) - nao ha o que avaliar.
            log.debug("Nenhum limiar configurado para paciente {} / {}", pacienteId, registro.getTipoSinalVital());
            return;
        }

        LimiarSeguranca limiar = limiarOpt.get();
        double valor = registro.getValorSinalVital();

        Optional<Gravidade> gravidade = ClassificadorGravidade.classificar(valor, limiar);
        if (gravidade.isEmpty()) {
            return;
        }
        boolean persistente = foraDaFaixaNoDiaAnterior(registro, limiar);

        String mensagem = String.format(PT_BR,
                "%s fora da faixa configurada: valor medido %.1f (faixa normal: %.1f a %.1f)",
                registro.getTipoSinalVital(), valor, limiar.getValorMin(), limiar.getValorMax());

        Alerta alerta = new Alerta(mensagem, registro);
        alerta.setGravidade(gravidade.get());
        alerta.setPersistente(persistente);
        alertaRepository.save(alerta);

        // O registro recebido do controller so tem o id do paciente; o limiar
        // vem do banco com o paciente completo.
        Paciente paciente = limiar.getPaciente();
        Cuidador cuidador = paciente != null && paciente.getCuidador() != null
                ? paciente.getCuidador() : limiar.getCuidador();
        boolean critico = gravidade.get() == Gravidade.CRITICO;
        RegistroSinalVital.TipoSinalVital tipo = registro.getTipoSinalVital();
        String titulo = (critico ? "🚨 Alerta crítico: " : "⚠️ Alerta: ") + tipo.getRotulo();
        String texto = String.format(PT_BR, "%s registrou %s %s %s (faixa configurada: %s a %s).%s",
                paciente != null ? paciente.getNome() : "O paciente",
                tipo.getRotulo().toLowerCase(PT_BR), formatar(valor), tipo.getUnidade(),
                formatar(limiar.getValorMin()), formatar(limiar.getValorMax()),
                persistente ? " Fora da faixa também ontem." : "");
        notificacaoService.notificarCuidador(cuidador, titulo, texto, critico || persistente);
    }

    private boolean foraDaFaixaNoDiaAnterior(RegistroSinalVital registro, LimiarSeguranca limiar) {
        LocalDate dia = registro.getHoraRegistro().toLocalDate();
        return registroSinalVitalRepository.findByPacienteIdAndTipoSinalVitalAndHoraRegistroBetween(
                        registro.getPaciente().getId(), registro.getTipoSinalVital(),
                        dia.minusDays(1).atStartOfDay(), dia.atStartOfDay().minus(1, ChronoUnit.MICROS))
                .stream()
                .anyMatch(r -> ClassificadorGravidade.classificar(r.getValorSinalVital(), limiar).isPresent());
    }

    private static String formatar(double valor) {
        return valor == Math.rint(valor) ? String.valueOf((long) valor) : String.format(PT_BR, "%.1f", valor);
    }
}
