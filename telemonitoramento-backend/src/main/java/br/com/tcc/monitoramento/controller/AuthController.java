package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.CadastroCuidadorRequest;
import br.com.tcc.monitoramento.dto.CadastroPacienteRequest;
import br.com.tcc.monitoramento.dto.LoginRequest;
import br.com.tcc.monitoramento.dto.TokenResponse;
import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.security.JwtService;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.CuidadorService;
import br.com.tcc.monitoramento.service.PacienteService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.*;

// RF01, RF03, RNF05: cadastro e login de pacientes e cuidadores.
@RestController
@RequestMapping("/auth")
public class AuthController {

    private final PacienteService pacienteService;
    private final CuidadorService cuidadorService;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final br.com.tcc.monitoramento.service.ConviteCuidadorService convites;
    private final br.com.tcc.monitoramento.service.AcessoAlternativoService acesso;

    public AuthController(PacienteService pacienteService,
                           CuidadorService cuidadorService,
                           AuthenticationManager authenticationManager,
                           JwtService jwtService,
                           br.com.tcc.monitoramento.service.ConviteCuidadorService convites,
                           br.com.tcc.monitoramento.service.AcessoAlternativoService acesso) {
        this.pacienteService = pacienteService;
        this.cuidadorService = cuidadorService;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.convites = convites;
        this.acesso = acesso;
    }

    @PostMapping("/cadastro/paciente")
    public ResponseEntity<TokenResponse> cadastrarPaciente(@Valid @RequestBody CadastroPacienteRequest request) {
        Paciente paciente = new Paciente(request.getNome(), request.getEmail(), null,
                request.getIdade(), br.com.tcc.monitoramento.service.Telefone.normalizar(request.getTelefone()));
        Paciente salvo = pacienteService.cadastrar(paciente, request.getSenha());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(gerarResposta(salvo.getId(), salvo.getEmail(), salvo.getSenhaHash(), salvo.getNome(), "PACIENTE"));
    }

    @PostMapping("/cadastro/cuidador")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<TokenResponse> cadastrarCuidador(@Valid @RequestBody CadastroCuidadorRequest request) {
        Cuidador cuidador = new Cuidador(request.getNome(), request.getEmail(), null,
                request.getIdade(), br.com.tcc.monitoramento.service.Telefone.normalizar(request.getTelefone()));
        Cuidador salvo = cuidadorService.cadastrar(cuidador, request.getSenha());
        convites.aceitar(request.getCodigoConvite(), salvo);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(gerarResposta(salvo.getId(), salvo.getEmail(), salvo.getSenhaHash(), salvo.getNome(), "CUIDADOR"));
    }

    // RF03: autentica e direciona para a interface do perfil correspondente (Paciente ou Cuidador).
    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        if (request.getPerfil() != null) {
            return ResponseEntity.ok(acesso.senha(request.getEmail(), request.getSenha(), request.getPerfil()));
        }
        try {
            var authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getSenha()));
            UsuarioAutenticado usuario = (UsuarioAutenticado) authentication.getPrincipal();
            return ResponseEntity.ok(acesso.sessaoPorUsuario(usuario));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
    }

    private TokenResponse gerarResposta(Long id, String email, String senhaHash, String nome, String tipo) {
        var usuario = new br.com.tcc.monitoramento.security.UsuarioAutenticado(
                id, email, senhaHash, br.com.tcc.monitoramento.security.TipoUsuario.valueOf(tipo));
        String token = jwtService.gerarToken(usuario);
        return new TokenResponse(token, tipo, id, nome);
    }

}
