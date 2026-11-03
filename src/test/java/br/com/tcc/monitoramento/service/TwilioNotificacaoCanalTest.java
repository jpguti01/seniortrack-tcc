package br.com.tcc.monitoramento.service;

import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class TwilioNotificacaoCanalTest {

    @Test
    void converteTelefoneBrasileiroParaE164() {
        assertEquals(Optional.of("+5511987654321"), TwilioNotificacaoCanal.paraE164("(11) 98765-4321"));
        assertEquals(Optional.of("+551133334444"), TwilioNotificacaoCanal.paraE164("11 3333-4444"));
        assertEquals(Optional.of("+5511987654321"), TwilioNotificacaoCanal.paraE164("+55 11 98765-4321"));
    }

    @Test
    void ignoraTelefoneAusenteInvalidoOuFicticio() {
        assertEquals(Optional.empty(), TwilioNotificacaoCanal.paraE164(null));
        assertEquals(Optional.empty(), TwilioNotificacaoCanal.paraE164("12345"));
        assertEquals(Optional.empty(), TwilioNotificacaoCanal.paraE164("(11) 00000-0000"));
    }

    @Test
    void ficaInativoSemCredenciais() {
        assertFalse(new TwilioNotificacaoCanal("", "", "", "").ativo());
        assertFalse(new TwilioNotificacaoCanal("sid", "token", "", "").ativo());
    }
}
