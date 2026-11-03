package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/**
 * RF05: pedido de vínculo entre um cuidador e um paciente. O vínculo só é
 * efetivado quando o PRÓPRIO paciente aceita (ver SolicitacaoVinculoService) -
 * um cuidador nunca se vincula a um paciente apenas por saber o e-mail dele.
 */
@Entity
@Table(name = "tb_solicitacao_vinculo")
public class SolicitacaoVinculo {

    public enum Status {
        PENDENTE, ACEITA, RECUSADA
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "cuidador_id")
    private Cuidador cuidador;

    @ManyToOne(optional = false)
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    public SolicitacaoVinculo() {
    }

    public SolicitacaoVinculo(Cuidador cuidador, Paciente paciente) {
        this.cuidador = cuidador;
        this.paciente = paciente;
        this.status = Status.PENDENTE;
        this.criadoEm = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Cuidador getCuidador() {
        return cuidador;
    }

    public void setCuidador(Cuidador cuidador) {
        this.cuidador = cuidador;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public void setPaciente(Paciente paciente) {
        this.paciente = paciente;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
