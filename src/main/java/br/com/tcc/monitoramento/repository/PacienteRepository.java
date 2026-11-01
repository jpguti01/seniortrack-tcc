package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Paciente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PacienteRepository extends JpaRepository<Paciente, Long> {

    Optional<Paciente> findByEmail(String email);

    boolean existsByEmail(String email);
}
