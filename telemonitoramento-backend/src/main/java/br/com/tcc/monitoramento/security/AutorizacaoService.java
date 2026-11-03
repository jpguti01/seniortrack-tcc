package br.com.tcc.monitoramento.security;

import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

/**
 * RNF05: garante que cuidadores e pacientes acessem estritamente os recursos
 * permitidos ao seu perfil - um paciente so ve os proprios dados, um cuidador
 * so ve os dados dos pacientes vinculados a ele. Lancar AccessDeniedException
 * aqui resulta em HTTP 403, tratado pelo proprio Spring Security.
 */
@Service
public class AutorizacaoService {

    private final PacienteRepository pacienteRepository;

    public AutorizacaoService(PacienteRepository pacienteRepository) {
        this.pacienteRepository = pacienteRepository;
    }

    public void garantirAcessoAoPaciente(Long pacienteId, UsuarioAutenticado usuario) {
        if (usuario.getTipo() == TipoUsuario.PACIENTE) {
            if (!usuario.getId().equals(pacienteId)) {
                throw new AccessDeniedException("Acesso negado aos dados deste paciente.");
            }
            return;
        }

        Paciente paciente = pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new AccessDeniedException("Acesso negado aos dados deste paciente."));
        if (paciente.getCuidador() == null || !paciente.getCuidador().getId().equals(usuario.getId())) {
            throw new AccessDeniedException("Acesso negado aos dados deste paciente.");
        }
    }

    // So o proprio cuidador vinculado pode resolver um alerta (nao o paciente).
    public void garantirCuidadorDoPaciente(Long pacienteId, UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.CUIDADOR) {
            throw new AccessDeniedException("Apenas o cuidador responsável pode realizar esta ação.");
        }
        garantirAcessoAoPaciente(pacienteId, usuario);
    }

    // RF07: so o proprio paciente edita/exclui o ultimo lancamento (nao o cuidador).
    public void garantirProprioPaciente(Long pacienteId, UsuarioAutenticado usuario) {
        if (usuario.getTipo() != TipoUsuario.PACIENTE || !usuario.getId().equals(pacienteId)) {
            throw new AccessDeniedException("Apenas o próprio paciente pode editar seus registros.");
        }
    }
}
