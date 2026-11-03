package br.com.tcc.monitoramento.model;

import br.com.tcc.monitoramento.security.TipoUsuario;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "tb_desafio_acesso")
public class DesafioAcesso {
    @Id public String telefone;
    @Column(unique = true, nullable = false) public String desafio;
    public String verificacaoSid;
    public Long usuarioId;
    @Enumerated(EnumType.STRING) public TipoUsuario perfil;
    public String finalidade;
    public Instant criadoEm;
    public Instant expiraEm;
    public int tentativas;
    public boolean consumido;

    public DesafioAcesso() {}
    public void renovar(TipoUsuario perfil, String finalidade, Long usuarioId) {
        this.desafio = UUID.randomUUID().toString();
        this.perfil = perfil;
        this.finalidade = finalidade;
        this.usuarioId = usuarioId;
        this.criadoEm = Instant.now();
        this.expiraEm = criadoEm.plusSeconds(600);
        this.tentativas = 0;
        this.consumido = false;
        this.verificacaoSid = null;
    }
}
