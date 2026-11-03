package br.com.tcc.monitoramento.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class RegistroSinalVitalJsonTest {
    private final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Test
    void historicoExpoeHorarioDaMedicao() throws Exception {
        RegistroSinalVital registro = new RegistroSinalVital();
        registro.setTipoSinalVital(RegistroSinalVital.TipoSinalVital.PRESSAO_ARTERIAL);
        registro.setValorSinalVital(120);
        registro.setHoraRegistro(LocalDateTime.of(2026, 11, 1, 8, 30));

        var json = mapper.readTree(mapper.writeValueAsString(registro));

        assertEquals("2026-11-01T08:30:00", json.get("horaRegistro").asText());
        assertEquals(120, json.get("valorSinalVital").asDouble());
    }

    @Test
    void clienteNaoPodeForjarHorarioDoRegistro() throws Exception {
        var registro = mapper.readValue("""
                {"tipoSinalVital":"PRESSAO_ARTERIAL","valorSinalVital":120,
                 "horaRegistro":"2000-01-01T00:00:00"}
                """, RegistroSinalVital.class);

        assertNull(registro.getHoraRegistro());
        assertEquals(120, registro.getValorSinalVital());
        assertEquals(RegistroSinalVital.TipoSinalVital.PRESSAO_ARTERIAL, registro.getTipoSinalVital());
    }
}
