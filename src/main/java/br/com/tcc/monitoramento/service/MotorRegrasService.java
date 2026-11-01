package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Alerta;
import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.AlertaRepository;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.Optional;

// RF09, UC-03: avalia um sinal vital recem-registrado contra o limiar
// configurado pelo cuidador e, se estiver fora da faixa, gera um alerta
// persistido e dispara a notificacao push (RNF03: em ate 2 segundos).
@Service
public class MotorRegrasService {

    private static final Logger log = LoggerFactory.getLogger(MotorRegrasService.class);

    private final LimiarSegurancaRepository limiarSegurancaRepository;
    private final AlertaRepository alertaRepository;
    private final NotificacaoService notificacaoService;

    public MotorRegrasService(LimiarSegurancaRepository limiarSegurancaRepository,
                               AlertaRepository alertaRepository,
                               NotificacaoService notificacaoService) {
        this.limiarSegurancaRepository = limiarSegurancaRepository;
        this.alertaRepository = alertaRepository;
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

        boolean foraDoLimiar = valor > limiar.getValorMax() || valor < limiar.getValorMin();
        if (!foraDoLimiar) {
            return;
        }

        String mensagem = String.format(Locale.forLanguageTag("pt-BR"),
                "%s fora da faixa configurada: valor medido %.1f (faixa normal: %.1f a %.1f)",
                registro.getTipoSinalVital(), valor, limiar.getValorMin(), limiar.getValorMax());

        Alerta alerta = new Alerta(mensagem, registro);
        alertaRepository.save(alerta);

        Cuidador cuidador = limiar.getCuidador();
        if (cuidador != null && cuidador.getTokenFcm() != null) {
            notificacaoService.enviarAlertaLimiar(cuidador.getTokenFcm(), mensagem);
        } else {
            log.warn("Alerta {} gerado, mas o cuidador nao tem token FCM registrado - notificacao nao enviada.", alerta.getId());
        }
    }
}
