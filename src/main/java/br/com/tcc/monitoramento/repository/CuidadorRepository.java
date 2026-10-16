package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.Cuidador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CuidadorRepository extends JpaRepository<Cuidador, Long> {

}
