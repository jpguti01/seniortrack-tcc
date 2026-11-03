package br.com.tcc.monitoramento.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

// RNF05: le o header "Authorization: Bearer <token>" e autentica a requisicao.
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtService jwtService;
    private final br.com.tcc.monitoramento.repository.PacienteRepository pacientes;
    private final br.com.tcc.monitoramento.repository.CuidadorRepository cuidadores;

    public JwtAuthenticationFilter(JwtService jwtService,
            br.com.tcc.monitoramento.repository.PacienteRepository pacientes,
            br.com.tcc.monitoramento.repository.CuidadorRepository cuidadores) {
        this.jwtService = jwtService;
        this.pacientes = pacientes;
        this.cuidadores = cuidadores;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                     @NonNull HttpServletResponse response,
                                     @NonNull FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);
        try {
            var claims = jwtService.validarEExtrairClaims(token);
            String email = claims.getSubject();
            Long id = claims.get("id", Long.class);
            TipoUsuario tipo = TipoUsuario.valueOf(claims.get("tipo", String.class));

            br.com.tcc.monitoramento.model.Usuario conta = tipo == TipoUsuario.PACIENTE
                    ? pacientes.findById(id).orElse(null) : cuidadores.findById(id).orElse(null);
            Number versao = claims.get("versao", Number.class);
            if (conta == null || conta.getVersaoSessao() != (versao == null ? 0 : versao.intValue())) {
                throw new JwtException("Sessão revogada. Entre novamente.");
            }

            var usuario = new UsuarioAutenticado(id, email, null, tipo);
            var authentication = new UsernamePasswordAuthenticationToken(usuario, null, usuario.getAuthorities());
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Token JWT invalido ou expirado: {}", e.getMessage());
            // Nao autentica; a cadeia de seguranca vai barrar o acesso a endpoints protegidos.
        }

        filterChain.doFilter(request, response);
    }
}
