package br.com.tcc.monitoramento.security;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.*;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.*;
import org.springframework.security.core.context.SecurityContextHolder;
import java.lang.reflect.Proxy;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;

class JwtSessionRevocationTest {
    private final JwtService jwt = new JwtService("segredo-de-teste-com-mais-de-trinta-e-dois-caracteres", 120);
    private final Paciente paciente = new Paciente("Maria", "maria@example.com", "hash", 70, "11999999999");

    @BeforeEach void preparar() { paciente.setId(1L); SecurityContextHolder.clearContext(); }
    @AfterEach void limpar() { SecurityContextHolder.clearContext(); }

    @Test void tokenDaVersaoAtualAutentica() throws Exception {
        filtrar(0, true);
        assertNotNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test void recuperarSenhaRevogaTokenAnterior() throws Exception {
        paciente.setVersaoSessao(1);
        filtrar(0, true);
        assertNull(SecurityContextHolder.getContext().getAuthentication());
        filtrar(1, true);
        assertNotNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test void contaExcluidaNaoAutentica() throws Exception {
        filtrar(0, false);
        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    private void filtrar(int versao, boolean existe) throws Exception {
        PacienteRepository pacientes = proxy(PacienteRepository.class, existe ? Optional.of(paciente) : Optional.empty());
        CuidadorRepository cuidadores = proxy(CuidadorRepository.class, Optional.empty());
        var filtro = new JwtAuthenticationFilter(jwt, pacientes, cuidadores);
        var request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer " + jwt.gerarToken(
                new UsuarioAutenticado(1L, "maria@example.com", null, TipoUsuario.PACIENTE), versao));
        filtro.doFilter(request, new MockHttpServletResponse(), new MockFilterChain());
    }

    @SuppressWarnings("unchecked")
    private <T> T proxy(Class<T> tipo, Object retorno) {
        return (T) Proxy.newProxyInstance(tipo.getClassLoader(), new Class<?>[]{tipo}, (p, metodo, args) -> retorno);
    }
}
