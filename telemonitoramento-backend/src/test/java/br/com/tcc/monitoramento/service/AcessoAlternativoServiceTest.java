package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.*;
import br.com.tcc.monitoramento.repository.*;
import br.com.tcc.monitoramento.security.*;
import org.junit.jupiter.api.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import java.lang.reflect.Proxy;
import java.time.Instant;
import java.util.*;
import java.util.function.BiFunction;
import static org.junit.jupiter.api.Assertions.*;

class AcessoAlternativoServiceTest {
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);
    private final JwtService jwt = new JwtService("segredo-de-teste-com-mais-de-trinta-e-dois-caracteres", 120);
    private final Paciente paciente = new Paciente("Maria", "maria@gmail.com", encoder.encode("senha123"), 70, "+5511999999999");
    private final Map<String, DesafioAcesso> desafios = new HashMap<>();
    private final MensagensFake mensagens = new MensagensFake();
    private List<Paciente> encontrados;
    private AcessoAlternativoService service;

    @BeforeEach
    void preparar() {
        paciente.setId(10L);
        encontrados = List.of(paciente);
        PacienteRepository pacientes = fake(PacienteRepository.class, (metodo, args) -> switch (metodo) {
            case "buscarPorTelefone" -> encontrados;
            case "findById", "findByEmailIgnoreCase" -> Optional.of(paciente);
            case "save" -> args[0];
            default -> throw new AssertionError(metodo);
        });
        CuidadorRepository cuidadores = fake(CuidadorRepository.class, (metodo, args) -> switch (metodo) {
            case "findByEmailIgnoreCase", "findById" -> Optional.empty();
            case "buscarPorTelefone" -> List.of();
            default -> throw new AssertionError(metodo);
        });
        DesafioAcessoRepository repositorio = fake(DesafioAcessoRepository.class, (metodo, args) -> switch (metodo) {
            case "bloquearTelefone" -> Optional.ofNullable(desafios.get(args[0]));
            case "bloquearDesafio" -> desafios.values().stream().filter(d -> d.desafio.equals(args[0])).findFirst();
            case "saveAndFlush" -> { var d = (DesafioAcesso) args[0]; desafios.put(d.telefone, d); yield d; }
            default -> throw new AssertionError(metodo);
        });
        service = new AcessoAlternativoService(pacientes, cuidadores, repositorio, mensagens, encoder, jwt, "");
    }

    @Test void normalizaCelularBrasileiro() {
        assertEquals("+5511999999999", Telefone.normalizar("(11) 99999-9999"));
        assertEquals("+5511999999999", Telefone.normalizar("+55 (11) 99999-9999"));
        assertThrows(IllegalArgumentException.class, () -> Telefone.normalizar("123"));
    }

    @Test void solicitaCodigoSemExporCodigoNemIdentificadorDoProvedor() {
        String id = solicitar("login");
        assertNotEquals("VE-teste", id);
        assertEquals(36, id.length());
        assertEquals(1, mensagens.envios);
        assertEquals("+5511999999999", mensagens.telefone);
        assertEquals(10L, desafio().usuarioId);
    }

    @Test void telefoneAusenteOuCompartilhadoRecebeDesafioSemEnviarMensagem() {
        encontrados = List.of();
        assertNotNull(solicitar("login"));
        assertEquals(0, mensagens.envios);
        assertNull(desafio().usuarioId);
        desafio().criadoEm = Instant.now().minusSeconds(61);
        encontrados = List.of(paciente, paciente);
        assertNotNull(solicitar("login"));
        assertEquals(0, mensagens.envios);
    }

    @Test void reenvioExigeUmMinutoEInvalidaDesafioAnterior() {
        String anterior = solicitar("login");
        var erro = assertThrows(ResponseStatusException.class, () -> solicitar("login"));
        assertEquals(429, erro.getStatusCode().value());
        assertEquals(1, mensagens.envios);
        desafio().criadoEm = Instant.now().minusSeconds(61);
        String novo = solicitar("login");
        assertNotEquals(anterior, novo);
        assertThrows(ResponseStatusException.class, () -> service.confirmar(anterior, "123456", "login", null));
    }

    @Test void desafioExpiradoNaoConsultaProvedor() {
        String id = solicitar("login");
        desafio().expiraEm = Instant.now().minusSeconds(1);
        assertThrows(ResponseStatusException.class, () -> service.confirmar(id, "123456", "login", null));
        assertEquals(0, mensagens.consultas);
    }

    @Test void cincoErrosBloqueiamNovasTentativas() {
        String id = solicitar("login");
        mensagens.aprovado = false;
        for (int i = 0; i < 6; i++) {
            assertThrows(ResponseStatusException.class, () -> service.confirmar(id, "000000", "login", null));
        }
        assertEquals(5, desafio().tentativas);
        assertEquals(5, mensagens.consultas);
    }

    @Test void codigoDeLoginNaoPodeRedefinirSenha() {
        String id = solicitar("login");
        assertThrows(ResponseStatusException.class, () -> service.confirmar(id, "123456", "recuperacao", "novasenha"));
        assertEquals(0, mensagens.consultas);
        assertTrue(encoder.matches("senha123", paciente.getSenhaHash()));
    }

    @Test void codigoValidoEmiteJwtESoPodeSerUsadoUmaVez() {
        String id = solicitar("login");
        var resposta = service.confirmar(id, "123456", "login", null);
        assertEquals("PACIENTE", resposta.getTipo());
        assertEquals(10L, jwt.validarEExtrairClaims(resposta.getToken()).get("id", Long.class));
        assertTrue(desafio().consumido);
        assertThrows(ResponseStatusException.class, () -> service.confirmar(id, "123456", "login", null));
        assertEquals(1, mensagens.consultas);
    }

    @Test void recuperacaoSalvaHashEEmiteNovaVersaoDaSessao() {
        String id = solicitar("recuperacao");
        var resposta = service.confirmar(id, "123456", "recuperacao", "novaSenha123");
        assertTrue(encoder.matches("novaSenha123", paciente.getSenhaHash()));
        assertFalse(encoder.matches("senha123", paciente.getSenhaHash()));
        assertEquals(1, paciente.getVersaoSessao());
        assertEquals(1, jwt.validarEExtrairClaims(resposta.getToken()).get("versao", Integer.class));
    }

    @Test void senhaRespeitaPerfilSelecionado() {
        assertEquals("PACIENTE", service.senha("maria@gmail.com", "senha123", TipoUsuario.PACIENTE).getTipo());
        assertThrows(ResponseStatusException.class, () -> service.senha("maria@gmail.com", "senha123", TipoUsuario.CUIDADOR));
        assertThrows(ResponseStatusException.class, () -> service.senha("maria@gmail.com", "errada", TipoUsuario.PACIENTE));
    }

    @Test void googleDesabilitadoNaoAceitaTokenDoCliente() {
        assertFalse(service.googleHabilitado());
        assertEquals(503, assertThrows(ResponseStatusException.class,
                () -> service.google("token-forjado", TipoUsuario.PACIENTE)).getStatusCode().value());
    }

    private String solicitar(String finalidade) { return service.solicitar("(11) 99999-9999", TipoUsuario.PACIENTE, finalidade, "whatsapp"); }
    private DesafioAcesso desafio() { return desafios.get("+5511999999999"); }

    @SuppressWarnings("unchecked")
    static <T> T fake(Class<T> tipo, BiFunction<String, Object[], Object> funcao) {
        return (T) Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo}, (proxy, metodo, args) -> {
            if (metodo.getName().equals("toString")) return tipo.getSimpleName();
            return funcao.apply(metodo.getName(), args);
        });
    }

    static class MensagensFake extends CodigoMensagemService {
        int envios, consultas;
        boolean aprovado = true;
        String telefone;
        MensagensFake() { super("", "", ""); }
        @Override public boolean habilitado() { return true; }
        @Override public String enviar(String telefone, String canal) { this.telefone = telefone; envios++; return "VE-teste"; }
        @Override public boolean verificar(String sid, String codigo) { consultas++; return aprovado; }
    }
}
