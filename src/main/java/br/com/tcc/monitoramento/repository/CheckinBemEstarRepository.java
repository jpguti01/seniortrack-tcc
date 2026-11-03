package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.CheckinBemEstar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface CheckinBemEstarRepository extends JpaRepository<CheckinBemEstar, Long> {

    Optional<CheckinBemEstar> findByPaciente_IdAndData(Long pacienteId, LocalDate data);

    List<CheckinBemEstar> findByPaciente_IdAndDataGreaterThanEqualOrderByDataDesc(Long pacienteId, LocalDate desde);
}
