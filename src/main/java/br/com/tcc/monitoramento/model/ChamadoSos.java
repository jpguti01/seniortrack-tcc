package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/**
 * Pedido de ajuda feito pelo paciente no botao SOS. Fica pendente no painel
 * do cuidador ate ele marcar como atendido.
 */
@Entity
@Table(name = "tb_chamado_sos")
public class ChamadoSos {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    @Column(nullable = false)
    private boolean atendido;

    @Column(name = "atendido_em")
    private LocalDateTime atendidoEm;

    public ChamadoSos() {
    }

    public ChamadoSos(Paciente paciente) {
        this.paciente = paciente;
        this.criadoEm = LocalDateTime.now();
        this.atendido = false;
    }

    public void marcarAtendido() {
        this.atendido = true;
        this.atendidoEm = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }

    public boolean isAtendido() {
        return atendido;
    }

    public LocalDateTime getAtendidoEm() {
        return atendidoEm;
    }
}
