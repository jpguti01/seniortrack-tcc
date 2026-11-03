package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.RegistroSinalVital.TipoSinalVital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LimiarSegurancaRepository extends JpaRepository<LimiarSeguranca, Long> {

    // Usado pelo MotorRegrasService para buscar o limiar vigente de um tipo de sinal (RF09, UC-03).
    Optional<LimiarSeguranca> findByPacienteIdAndTipoSinalVital(Long pacienteId, TipoSinalVital tipoSinalVital);

    // RF10: lista os limiares configurados de um paciente.
    List<LimiarSeguranca> findByPacienteId(Long pacienteId);
}
