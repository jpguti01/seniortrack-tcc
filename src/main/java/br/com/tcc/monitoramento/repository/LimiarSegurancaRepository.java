package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LimiarSegurancaRepository extends JpaRepository<LimiarSeguranca, Long> {
}
