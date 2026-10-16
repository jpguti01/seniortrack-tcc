package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.RegistroSinalVital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface RegistroSinalVitalRepository extends JpaRepository<RegistroSinalVital, Long> {
}
