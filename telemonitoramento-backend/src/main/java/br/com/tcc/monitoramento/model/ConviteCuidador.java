package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "tb_convite_cuidador")
public class ConviteCuidador {
    @Id public Long pacienteId;
    @Column(nullable = false, unique = true) public String codigoHash;
    public Instant expiraEm;
    public boolean usado;
    public ConviteCuidador() {}
}
