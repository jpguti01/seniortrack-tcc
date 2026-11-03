package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.ChamadoSos;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChamadoSosRepository extends JpaRepository<ChamadoSos, Long> {

    List<ChamadoSos> findByPaciente_IdAndCriadoEmAfterOrderByCriadoEmDesc(Long pacienteId, LocalDateTime desde);

    List<ChamadoSos> findByPaciente_IdAndAtendidoFalseOrderByCriadoEmDesc(Long pacienteId);

    // Evita disparar varias notificacoes quando o botao e' tocado repetidamente.
    Optional<ChamadoSos> findFirstByPaciente_IdAndAtendidoFalseAndCriadoEmAfterOrderByCriadoEmDesc(Long pacienteId,
                                                                                                    LocalDateTime desde);
}
