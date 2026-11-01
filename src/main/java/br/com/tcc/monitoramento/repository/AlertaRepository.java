package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertaRepository extends JpaRepository<Alerta, Long> {

    // RF10: historico de alertas do paciente para o dashboard do cuidador, mais recentes primeiro.
    // Os underscores marcam explicitamente cada travessia de relacionamento
    // (Alerta -> registroSinalVital -> paciente -> id), evitando ambiguidade na derivacao da query.
    List<Alerta> findByRegistroSinalVital_Paciente_IdOrderByDataHoraDesc(Long pacienteId);
}
