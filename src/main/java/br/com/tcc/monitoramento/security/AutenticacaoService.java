package br.com.tcc.monitoramento.security;

import br.com.tcc.monitoramento.model.Cuidador;
import br.com.tcc.monitoramento.model.Paciente;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * Paciente e Cuidador vivem em tabelas separadas (tb_paciente, tb_cuidador),
 * entao o login procura o e-mail em ambas, nessa ordem.
 */
@Service
public class AutenticacaoService implements UserDetailsService {

    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;

    public AutenticacaoService(PacienteRepository pacienteRepository, CuidadorRepository cuidadorRepository) {
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var paciente = pacienteRepository.findByEmail(email);
        if (paciente.isPresent()) {
            Paciente p = paciente.get();
            return new UsuarioAutenticado(p.getId(), p.getEmail(), p.getSenhaHash(), TipoUsuario.PACIENTE);
        }

        var cuidador = cuidadorRepository.findByEmail(email);
        if (cuidador.isPresent()) {
            Cuidador c = cuidador.get();
            return new UsuarioAutenticado(c.getId(), c.getEmail(), c.getSenhaHash(), TipoUsuario.CUIDADOR);
        }

        throw new UsernameNotFoundException("Nenhum usuario encontrado com o e-mail: " + email);
    }
}
