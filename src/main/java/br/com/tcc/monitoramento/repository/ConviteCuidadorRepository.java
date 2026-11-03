package br.com.tcc.monitoramento.repository;

import br.com.tcc.monitoramento.model.ConviteCuidador;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface ConviteCuidadorRepository extends JpaRepository<ConviteCuidador, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from ConviteCuidador c where c.codigoHash = :hash")
    Optional<ConviteCuidador> bloquearCodigo(@Param("hash") String hash);
}
