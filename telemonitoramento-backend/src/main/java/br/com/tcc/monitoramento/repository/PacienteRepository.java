package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Paciente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PacienteRepository extends JpaRepository<Paciente, Long> {

    Optional<Paciente> findByEmail(String email);

    Optional<Paciente> findByEmailIgnoreCase(String email);

    @org.springframework.data.jpa.repository.Query(value = "select * from tb_paciente where regexp_replace(telefone, '[^0-9]', '', 'g') in (:internacional, :nacional)", nativeQuery = true)
    java.util.List<Paciente> buscarPorTelefone(@org.springframework.data.repository.query.Param("internacional") String internacional,
            @org.springframework.data.repository.query.Param("nacional") String nacional);

    boolean existsByEmail(String email);

    // RNF05: um cuidador so deve listar os pacientes vinculados a ele, nunca todos do sistema.
    java.util.List<Paciente> findByCuidadorId(Long cuidadorId);
}
