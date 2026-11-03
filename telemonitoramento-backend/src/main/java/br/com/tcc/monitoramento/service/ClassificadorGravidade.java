package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Gravidade;
import br.com.tcc.monitoramento.model.LimiarSeguranca;

import java.util.Optional;

/**
 * Classifica uma medicao em relacao a faixa configurada pelo cuidador (RF08):
 * dentro da faixa = normal (Optional vazio); fora da faixa = ATENCAO; mais de
 * 25% alem do limite = CRITICO. Ex.: com faixa de glicemia 70-140 mg/dL, 165
 * e' ATENCAO e 250 e' CRITICO; com pressao ate 130 mmHg, 155 e' ATENCAO e 180
 * e' CRITICO.
 *
 * A mesma regra existe no app Flutter (lib/models/status_medicao.dart) para
 * colorir os cards; mantenha as duas iguais. As faixas sao configuradas por
 * paciente e nao representam uma recomendacao clinica.
 */
public final class ClassificadorGravidade {

    public static final double MARGEM_CRITICA = 0.25;

    private ClassificadorGravidade() {
    }

    public static Optional<Gravidade> classificar(double valor, LimiarSeguranca limiar) {
        return classificar(valor, limiar.getValorMin(), limiar.getValorMax());
    }

    public static Optional<Gravidade> classificar(double valor, double minimo, double maximo) {
        if (valor >= minimo && valor <= maximo) {
            return Optional.empty();
        }
        boolean critico = valor > maximo * (1 + MARGEM_CRITICA) || valor < minimo * (1 - MARGEM_CRITICA);
        return Optional.of(critico ? Gravidade.CRITICO : Gravidade.ATENCAO);
    }
}
