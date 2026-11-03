package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.model.SolicitacaoVinculo;
import br.com.tcc.monitoramento.model.SolicitacaoVinculo.Status;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.SolicitacaoVinculoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * RF05: um cuidador SOLICITA o vínculo por e-mail; o vínculo só é efetivado
 * quando o próprio paciente aceita. Isto evita que qualquer pessoa que saiba
 * o e-mail de um paciente ganhe acesso ao histórico de saúde dele sem
 * consentimento.
 */
@Service
public class SolicitacaoVinculoService {

    private final SolicitacaoVinculoRepository solicitacaoRepository;
    private final CuidadorRepository cuidadorRepository;
    private final PacienteRepository pacienteRepository;

    public SolicitacaoVinculoService(SolicitacaoVinculoRepository solicitacaoRepository,
                                      CuidadorRepository cuidadorRepository,
                                      PacienteRepository pacienteRepository) {
        this.solicitacaoRepository = solicitacaoRepository;
        this.cuidadorRepository = cuidadorRepository;
        this.pacienteRepository = pacienteRepository;
    }

    // Sempre silenciosa: nao revela se o e-mail pertence a um paciente
    // cadastrado (evita enumeracao). So cria a solicitacao pendente quando ha
    // correspondencia e ainda nao existe um pedido pendente igual.
    public void solicitar(Long cuidadorId, String emailPaciente) {
        Optional<Paciente> pacienteOpt = pacienteRepository.findByEmail(emailPaciente);
        if (pacienteOpt.isEmpty()) {
            return;
        }
        Paciente paciente = pacienteOpt.get();

        if (solicitacaoRepository.existsByCuidador_IdAndPaciente_IdAndStatus(cuidadorId, paciente.getId(), Status.PENDENTE)) {
            return;
        }

        Cuidador cuidador = cuidadorRepository.findById(cuidadorId)
                .orElseThrow(() -> new NegocioException("Cuidador não encontrado."));

        solicitacaoRepository.save(new SolicitacaoVinculo(cuidador, paciente));
    }

    public List<SolicitacaoVinculo> listarPendentes(Long pacienteId) {
        return solicitacaoRepository.findByPaciente_IdAndStatusOrderByCriadoEmDesc(pacienteId, Status.PENDENTE);
    }

    // So o proprio paciente da solicitacao pode aceitar - a checagem de posse
    // fica no controller (AutorizacaoService), aqui so a regra de negocio.
    public void aceitar(Long solicitacaoId) {
        SolicitacaoVinculo solicitacao = buscarPendente(solicitacaoId);
        Cuidador cuidador = solicitacao.getCuidador();
        Paciente paciente = solicitacao.getPaciente();
        cuidador.adicionarPaciente(paciente);
        pacienteRepository.save(paciente);
        solicitacao.setStatus(Status.ACEITA);
        solicitacaoRepository.save(solicitacao);
    }

    public void recusar(Long solicitacaoId) {
        SolicitacaoVinculo solicitacao = buscarPendente(solicitacaoId);
        solicitacao.setStatus(Status.RECUSADA);
        solicitacaoRepository.save(solicitacao);
    }

    private SolicitacaoVinculo buscarPendente(Long id) {
        SolicitacaoVinculo solicitacao = solicitacaoRepository.findById(id)
                .orElseThrow(() -> new NegocioException("Solicitação não encontrada."));
        if (solicitacao.getStatus() != Status.PENDENTE) {
            throw new NegocioException("Esta solicitação já foi respondida.");
        }
        return solicitacao;
    }

    public SolicitacaoVinculo buscarPorId(Long id) {
        return solicitacaoRepository.findById(id)
                .orElseThrow(() -> new NegocioException("Solicitação não encontrada."));
    }
}
