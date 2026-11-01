package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.model.RegistroSinalVital.TipoSinalVital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;


@Repository
public interface RegistroSinalVitalRepository extends JpaRepository<RegistroSinalVital, Long> {

    // RF10: historico do paciente para o dashboard, mais recente primeiro.
    List<RegistroSinalVital> findByPacienteIdOrderByHoraRegistroDesc(Long pacienteId);

    // RF11: filtro por tipo de sinal e por periodo.
    List<RegistroSinalVital> findByPacienteIdAndTipoSinalVitalOrderByHoraRegistroDesc(Long pacienteId, TipoSinalVital tipoSinalVital);

    List<RegistroSinalVital> findByPacienteIdAndHoraRegistroBetweenOrderByHoraRegistroDesc(Long pacienteId, LocalDateTime desde, LocalDateTime ate);

    // RF07: o ultimo lancamento do paciente, para edicao/exclusao.
    Optional<RegistroSinalVital> findFirstByPacienteIdOrderByHoraRegistroDesc(Long pacienteId);
}
