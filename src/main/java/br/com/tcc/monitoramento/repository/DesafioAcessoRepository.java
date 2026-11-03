package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.DesafioAcesso;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface DesafioAcessoRepository extends JpaRepository<DesafioAcesso, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from DesafioAcesso d where d.telefone = :telefone")
    Optional<DesafioAcesso> bloquearTelefone(@Param("telefone") String telefone);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from DesafioAcesso d where d.desafio = :desafio")
    Optional<DesafioAcesso> bloquearDesafio(@Param("desafio") String desafio);
}
