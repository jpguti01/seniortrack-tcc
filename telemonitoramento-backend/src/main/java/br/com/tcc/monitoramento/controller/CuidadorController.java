package br.com.tcc.monitoramento.controller;

import br.com.tcc.monitoramento.dto.ChamadoSosResponse;
import br.com.tcc.monitoramento.dto.CheckinBemEstarResponse;
import br.com.tcc.monitoramento.dto.DoseResponse;
import br.com.tcc.monitoramento.dto.PainelPacienteResponse;
import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.security.TipoUsuario;
import br.com.tcc.monitoramento.security.UsuarioAutenticado;
import br.com.tcc.monitoramento.service.BemEstarService;
import br.com.tcc.monitoramento.service.CuidadorService;
import br.com.tcc.monitoramento.service.MedicamentoService;
import br.com.tcc.monitoramento.service.NotificacaoService;
import br.com.tcc.monitoramento.service.PacienteService;
import br.com.tcc.monitoramento.service.SolicitacaoVinculoService;
import br.com.tcc.monitoramento.service.SosService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


@RestController
@RequestMapping("/cuidador")

public class CuidadorController {

    private final CuidadorService cuidadorService;
    private final SolicitacaoVinculoService solicitacaoVinculoService;
    private final PacienteService pacienteService;
    private final SosService sosService;
    private final MedicamentoService medicamentoService;
    private final BemEstarService bemEstarService;
    private final NotificacaoService notificacaoService;

    public CuidadorController(CuidadorService cuidadorService, SolicitacaoVinculoService solicitacaoVinculoService,
                              PacienteService pacienteService, SosService sosService,
                              MedicamentoService medicamentoService, BemEstarService bemEstarService,
                              NotificacaoService notificacaoService){
        this.cuidadorService = cuidadorService;
        this.solicitacaoVinculoService = solicitacaoVinculoService;
        this.pacienteService = pacienteService;
        this.sosService = sosService;
        this.medicamentoService = medicamentoService;
        this.bemEstarService = bemEstarService;
        this.notificacaoService = notificacaoService;
    }

    // Pendencias do dia de todos os pacientes do cuidador autenticado (SOS,
    // remedios sem confirmacao, check-in de bem-estar) em uma unica chamada.
    @GetMapping("/painel")
    public ResponseEntity<List<PainelPacienteResponse>> painel(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        garantirCuidador(usuario);
        LocalDateTime agora = LocalDateTime.now();
        List<PainelPacienteResponse> painel = new ArrayList<>();
        for (Paciente paciente : pacienteService.listarPorCuidador(usuario.getId())) {
            List<DoseResponse> doses = medicamentoService.dosesDoDia(paciente.getId(), agora.toLocalDate(), agora);
            painel.add(new PainelPacienteResponse(
                    paciente.getId(),
                    sosService.listarPendentes(paciente.getId()).stream().map(ChamadoSosResponse::new).toList(),
                    (int) doses.stream().filter(d -> d.status().equals(MedicamentoService.StatusDose.ATRASADO.name())).count(),
                    doses.size(),
                    bemEstarService.doDia(paciente.getId(), agora.toLocalDate()).map(CheckinBemEstarResponse::new).orElse(null)));
        }
        return ResponseEntity.ok(painel);
    }

    // Canais externos configurados no servidor (WhatsApp/SMS/webhook), para o app informar o cuidador.
    @GetMapping("/canais-notificacao")
    public ResponseEntity<List<String>> canaisNotificacao(@AuthenticationPrincipal UsuarioAutenticado usuario) {
        garantirCuidador(usuario);
        return ResponseEntity.ok(notificacaoService.canaisExternosAtivos());
    }

    private void garantirCuidador(UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.CUIDADOR) {
            throw new AccessDeniedException("Apenas cuidadores acessam o painel.");
        }
    }

    // O cadastro de cuidadores acontece em POST /auth/cadastro/cuidador (AuthController),
    // unico fluxo que define a senha com hash.

    // RF09: o app Flutter chama este endpoint apos obter/renovar o token FCM do dispositivo.
    // Sem {id} na URL de proposito: o cuidador so pode atualizar o proprio token,
    // identificado pelo token JWT, nunca o de outro cuidador.
    @PutMapping("/token-fcm")
    public ResponseEntity<Void> atualizarTokenFcm(@RequestBody String tokenFcm,
                                                    @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.CUIDADOR) {
            throw new AccessDeniedException("Apenas cuidadores possuem token FCM.");
        }
        Cuidador cuidador = cuidadorService.buscarPorId(usuario.getId());
        if (cuidador == null) {
            return ResponseEntity.notFound().build();
        }
        cuidador.setTokenFcm(tokenFcm);
        cuidadorService.salvar(cuidador);
        return ResponseEntity.noContent().build();
    }


    // RF05, US05: o cuidador apenas SOLICITA o vínculo por e-mail - o vínculo
    // de verdade so acontece quando o paciente aceita (ver PacienteController).
    // A resposta e' sempre a mesma genérica, exista ou não esse e-mail, para
    // que um cuidador não consiga descobrir quais e-mails tem cadastro de
    // paciente (evita enumeração).
    @PostMapping("/pacientes/vincular")
    public ResponseEntity<Map<String, String>> solicitarVinculo(@RequestBody Map<String, String> corpo,
                                                                  @AuthenticationPrincipal UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.CUIDADOR) {
            throw new AccessDeniedException("Apenas cuidadores podem solicitar vínculo com pacientes.");
        }
        String email = corpo.get("emailPaciente");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        solicitacaoVinculoService.solicitar(usuario.getId(), email);
        return ResponseEntity.accepted().body(Map.of(
                "mensagem", "Se existir um paciente cadastrado com este e-mail, uma solicitação de vínculo foi enviada a ele."
        ));
    }

    @GetMapping
    public ResponseEntity<List<Cuidador>> listar(){
        List<Cuidador> listaCuidador = cuidadorService.listar();
        return ResponseEntity.ok(listaCuidador);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Cuidador> buscarPorId(@PathVariable Long id) {
        Cuidador cuidador = cuidadorService.buscarPorId(id);
        if (cuidador == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(cuidador);
    }
}
