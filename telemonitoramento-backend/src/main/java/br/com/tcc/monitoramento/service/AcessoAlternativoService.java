package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.dto.TokenResponse;
import br.com.tcc.monitoramento.model.*;
import br.com.tcc.monitoramento.repository.*;
import br.com.tcc.monitoramento.security.*;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.Instant;
import java.util.List;

@Service
public class AcessoAlternativoService {
    private final PacienteRepository pacientes;
    private final CuidadorRepository cuidadores;
    private final DesafioAcessoRepository desafios;
    private final CodigoMensagemService mensagens;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final String googleClientId;
    private final GoogleIdTokenVerifier googleVerifier;

    public AcessoAlternativoService(PacienteRepository pacientes, CuidadorRepository cuidadores,
            DesafioAcessoRepository desafios, CodigoMensagemService mensagens,
            PasswordEncoder encoder, JwtService jwt, @Value("${auth.google.client-id:}") String googleClientId) {
        this.pacientes = pacientes; this.cuidadores = cuidadores; this.desafios = desafios;
        this.mensagens = mensagens; this.encoder = encoder; this.jwt = jwt; this.googleClientId = googleClientId;
        this.googleVerifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
                .setAudience(List.of(googleClientId)).build();
    }

    public boolean googleHabilitado() { return !googleClientId.isBlank(); }

    public TokenResponse senha(String email, String senha, TipoUsuario perfil) {
        Usuario usuario = perfil == TipoUsuario.PACIENTE
                ? pacientes.findByEmailIgnoreCase(email.trim()).orElse(null)
                : cuidadores.findByEmailIgnoreCase(email.trim()).orElse(null);
        if (usuario == null || !encoder.matches(senha, usuario.getSenhaHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "E-mail ou senha incorretos.");
        }
        return sessao(usuario, perfil);
    }

    @Transactional
    public String solicitar(String telefone, TipoUsuario perfil, String finalidade, String canal) {
        if (!List.of("login", "recuperacao").contains(finalidade) || !List.of("sms", "whatsapp").contains(canal)) {
            throw new IllegalArgumentException("Escolha SMS ou WhatsApp para receber o código.");
        }
        if (!mensagens.habilitado()) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "O envio de códigos está indisponível. Entre com e-mail e senha.");
        String numero = Telefone.normalizar(telefone);
        DesafioAcesso desafio = desafios.bloquearTelefone(numero).orElseGet(DesafioAcesso::new);
        if (desafio.criadoEm != null && desafio.criadoEm.plusSeconds(60).isAfter(Instant.now())) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS,
                    "Aguarde um minuto antes de pedir outro código.");
        }
        List<? extends Usuario> encontrados = perfil == TipoUsuario.PACIENTE
                ? pacientes.buscarPorTelefone(numero.substring(1), numero.substring(3))
                : cuidadores.buscarPorTelefone(numero.substring(1), numero.substring(3));
        desafio.telefone = numero;
        desafio.renovar(perfil, finalidade, encontrados.size() == 1 ? encontrados.get(0).getId() : null);
        desafios.saveAndFlush(desafio);
        // A resposta é idêntica para telefones ausentes ou compartilhados por várias contas.
        if (desafio.usuarioId != null) desafio.verificacaoSid = mensagens.enviar(numero, canal);
        return desafio.desafio;
    }

    @Transactional(noRollbackFor = ResponseStatusException.class)
    public TokenResponse confirmar(String identificador, String codigo, String finalidade, String novaSenha) {
        var d = desafios.bloquearDesafio(identificador).orElseThrow(this::codigoInvalido);
        if (d.consumido || !d.expiraEm.isAfter(Instant.now()) || d.tentativas >= 5 || !d.finalidade.equals(finalidade)) {
            throw codigoInvalido();
        }
        d.tentativas++;
        if (d.verificacaoSid == null || !mensagens.verificar(d.verificacaoSid, codigo)) throw codigoInvalido();
        d.consumido = true;
        Usuario usuario = buscar(d.perfil, d.usuarioId);
        if (finalidade.equals("recuperacao")) {
            usuario.setSenhaHash(encoder.encode(novaSenha));
            usuario.setVersaoSessao(usuario.getVersaoSessao() + 1);
            if (usuario instanceof Paciente p) pacientes.save(p);
            else cuidadores.save((Cuidador) usuario);
        }
        return sessao(usuario, d.perfil);
    }

    public TokenResponse google(String idToken, TipoUsuario perfil) {
        if (!googleHabilitado()) throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "O acesso com Google está indisponível. Entre com e-mail e senha.");
        try {
            var token = googleVerifier.verify(idToken);
            if (token == null || !Boolean.TRUE.equals(token.getPayload().getEmailVerified())) throw googleInvalido();
            var payload = token.getPayload();
            String email = payload.getEmail();
            if (email == null || email.isBlank()) throw googleInvalido();
            // Google só é autoridade do endereço em Gmail ou Workspace verificado.
            if (!email.endsWith("@gmail.com") &&
                    (payload.getHostedDomain() == null || payload.getHostedDomain().isBlank())) throw googleInvalido();
            Usuario usuario = perfil == TipoUsuario.PACIENTE
                    ? pacientes.findByEmailIgnoreCase(email).orElseThrow(this::googleInvalido)
                    : cuidadores.findByEmailIgnoreCase(email).orElseThrow(this::googleInvalido);
            return sessao(usuario, perfil);
        } catch (java.security.GeneralSecurityException | java.io.IOException | IllegalArgumentException e) {
            throw googleInvalido();
        }
    }

    private Usuario buscar(TipoUsuario perfil, Long id) {
        return perfil == TipoUsuario.PACIENTE ? pacientes.findById(id).orElseThrow(this::codigoInvalido)
                : cuidadores.findById(id).orElseThrow(this::codigoInvalido);
    }

    private TokenResponse sessao(Usuario u, TipoUsuario perfil) {
        String token = jwt.gerarToken(new UsuarioAutenticado(u.getId(), u.getEmail(), u.getSenhaHash(), perfil), u.getVersaoSessao());
        return new TokenResponse(token, perfil.name(), u.getId(), u.getNome());
    }

    public TokenResponse sessaoPorUsuario(UsuarioAutenticado usuario) {
        return sessao(buscar(usuario.getTipo(), usuario.getId()), usuario.getTipo());
    }

    private ResponseStatusException codigoInvalido() {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Código inválido ou expirado. Confira os seis dígitos ou solicite outro código.");
    }
    private ResponseStatusException googleInvalido() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                "Não foi possível entrar com Google. Use a conta Google do e-mail cadastrado e confira o perfil escolhido.");
    }
}
