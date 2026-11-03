package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.SolicitacaoVinculo;
import br.com.tcc.monitoramento.model.SolicitacaoVinculo.Status;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SolicitacaoVinculoRepository extends JpaRepository<SolicitacaoVinculo, Long> {

    List<SolicitacaoVinculo> findByPaciente_IdAndStatusOrderByCriadoEmDesc(Long pacienteId, Status status);

    boolean existsByCuidador_IdAndPaciente_IdAndStatus(Long cuidadorId, Long pacienteId, Status status);
}
