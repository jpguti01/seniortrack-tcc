package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.*;
import br.com.tcc.monitoramento.repository.ConviteCuidadorRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.*;
import java.time.Instant;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static br.com.tcc.monitoramento.service.AcessoAlternativoServiceTest.fake;

class ConviteCuidadorServiceTest {
    private final Paciente paciente = new Paciente();
    private final Cuidador cuidador = new Cuidador();
    private ConviteCuidador convite;
    private ConviteCuidadorService service;
    private String hashConsultado;

    @BeforeEach void preparar() {
        paciente.setId(7L);
        var repo = fake(ConviteCuidadorRepository.class, (metodo, args) -> switch (metodo) {
            case "findById" -> Optional.ofNullable(convite);
            case "save" -> { convite = (ConviteCuidador) args[0]; yield convite; }
            case "bloquearCodigo" -> convite != null && convite.codigoHash.equals(args[0]) ? Optional.of(convite) : Optional.empty();
            default -> throw new AssertionError(metodo);
        });
        EntityManager em = fake(EntityManager.class, (metodo, args) -> switch (metodo) {
            case "find" -> paciente;
            case "createQuery" -> consulta();
            default -> throw new AssertionError(metodo);
        });
        service = new ConviteCuidadorService(repo, em);
    }

    @Test void conviteTemHashValidadeEVinculaUmaUnicaVez() {
        String codigo = service.gerar(7L);
        assertTrue(codigo.matches("[A-F0-9]{20}"));
        assertNotEquals(codigo, convite.codigoHash);
        assertTrue(convite.expiraEm.isAfter(Instant.now().plusSeconds(86390)));
        service.aceitar(codigo.toLowerCase(Locale.ROOT), cuidador);
        assertSame(cuidador, paciente.getCuidador());
        assertTrue(convite.usado);
        assertThrows(IllegalArgumentException.class, () -> service.aceitar(codigo, new Cuidador()));
    }

    @Test void gerarOutroInvalidaAnterior() {
        String anterior = service.gerar(7L);
        String novo = service.gerar(7L);
        assertNotEquals(anterior, novo);
        assertThrows(IllegalArgumentException.class, () -> service.aceitar(anterior, cuidador));
        service.aceitar(novo, cuidador);
        assertSame(cuidador, paciente.getCuidador());
    }

    @Test void conviteExpiradoNaoVincula() {
        String codigo = service.gerar(7L);
        convite.expiraEm = Instant.now().minusSeconds(1);
        assertThrows(IllegalArgumentException.class, () -> service.aceitar(codigo, cuidador));
        assertNull(paciente.getCuidador());
    }

    @Test void conviteNaoSubstituiCuidadorExistente() {
        String codigo = service.gerar(7L);
        Cuidador existente = new Cuidador();
        paciente.setCuidador(existente);
        assertThrows(IllegalArgumentException.class, () -> service.aceitar(codigo, cuidador));
        assertSame(existente, paciente.getCuidador());
    }

    @Test void cadastroSemConviteContinuaPossivel() {
        service.aceitar(null, cuidador);
        service.aceitar(" ", cuidador);
        assertNull(paciente.getCuidador());
    }

    private TypedQuery<?> consulta() {
        return fake(TypedQuery.class, (metodo, args) -> switch (metodo) {
            case "setParameter" -> { hashConsultado = (String) args[1]; yield consulta(); }
            case "getResultStream" -> convite != null && convite.codigoHash.equals(hashConsultado)
                    ? java.util.stream.Stream.of(7L) : java.util.stream.Stream.empty();
            default -> throw new AssertionError(metodo);
        });
    }
}
