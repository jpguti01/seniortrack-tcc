package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.TomadaMedicamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TomadaMedicamentoRepository extends JpaRepository<TomadaMedicamento, Long> {

    Optional<TomadaMedicamento> findByMedicamento_IdAndDataAndHorario(Long medicamentoId, LocalDate data, LocalTime horario);

    List<TomadaMedicamento> findByMedicamento_Paciente_IdAndDataBetween(Long pacienteId, LocalDate desde, LocalDate ate);
}
