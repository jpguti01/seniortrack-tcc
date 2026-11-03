package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Cuidador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CuidadorRepository extends JpaRepository<Cuidador, Long> {

    Optional<Cuidador> findByEmail(String email);

    Optional<Cuidador> findByEmailIgnoreCase(String email);

    @org.springframework.data.jpa.repository.Query(value = "select * from tb_cuidador where regexp_replace(telefone, '[^0-9]', '', 'g') in (:internacional, :nacional)", nativeQuery = true)
    java.util.List<Cuidador> buscarPorTelefone(@org.springframework.data.repository.query.Param("internacional") String internacional,
            @org.springframework.data.repository.query.Param("nacional") String nacional);

    boolean existsByEmail(String email);
}
