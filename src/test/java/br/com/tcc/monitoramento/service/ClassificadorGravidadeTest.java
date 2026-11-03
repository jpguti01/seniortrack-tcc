package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Gravidade;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ClassificadorGravidadeTest {

    @Test
    void dentroDaFaixaIncluindoOsLimitesENormal() {
        assertEquals(Optional.empty(), ClassificadorGravidade.classificar(70, 70, 140));
        assertEquals(Optional.empty(), ClassificadorGravidade.classificar(140, 70, 140));
    }

    @Test
    void levementeForaDaFaixaEAtencao() {
        assertEquals(Optional.of(Gravidade.ATENCAO), ClassificadorGravidade.classificar(165, 70, 140));
        assertEquals(Optional.of(Gravidade.ATENCAO), ClassificadorGravidade.classificar(155, 80, 130));
        assertEquals(Optional.of(Gravidade.ATENCAO), ClassificadorGravidade.classificar(60, 70, 140));
    }

    @Test
    void maisDe25PorCentoAlemDoLimiteECritico() {
        assertEquals(Optional.of(Gravidade.CRITICO), ClassificadorGravidade.classificar(250, 70, 140));
        assertEquals(Optional.of(Gravidade.CRITICO), ClassificadorGravidade.classificar(180, 80, 130));
        assertEquals(Optional.of(Gravidade.CRITICO), ClassificadorGravidade.classificar(50, 70, 140));
        // Exatamente 25% acima ainda e' atencao.
        assertEquals(Optional.of(Gravidade.ATENCAO), ClassificadorGravidade.classificar(175, 70, 140));
    }
}
