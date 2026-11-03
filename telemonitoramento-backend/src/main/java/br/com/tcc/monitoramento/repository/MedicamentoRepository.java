package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Medicamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicamentoRepository extends JpaRepository<Medicamento, Long> {

    List<Medicamento> findByPaciente_IdAndAtivoTrueOrderByNomeAsc(Long pacienteId);

    // Inclui os desativados: o relatorio de adesao considera as doses do periodo em que estavam ativos.
    List<Medicamento> findByPaciente_IdOrderByNomeAsc(Long pacienteId);

    List<Medicamento> findByAtivoTrue();
}
