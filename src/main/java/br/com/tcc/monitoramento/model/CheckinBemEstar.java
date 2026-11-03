package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Check-in diario "Como voce esta se sentindo hoje?". Um por paciente por dia;
 * responder de novo no mesmo dia atualiza a resposta. Serve para o cuidador
 * relacionar variacoes dos sinais vitais com o que o paciente relatou.
 */
@Entity
@Table(name = "tb_checkin_bem_estar",
        uniqueConstraints = @UniqueConstraint(columnNames = {"paciente_id", "data"}))
public class CheckinBemEstar {

    public enum Humor {
        OTIMO, BEM, COM_DOR, MAL;

        public boolean preocupante() {
            return this == COM_DOR || this == MAL;
        }
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    @Column(nullable = false)
    private LocalDate data;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Humor humor;

    @Column(length = 255)
    private String observacao;

    @Column(name = "registrado_em", nullable = false)
    private LocalDateTime registradoEm;

    public CheckinBemEstar() {
    }

    public CheckinBemEstar(Paciente paciente, LocalDate data) {
        this.paciente = paciente;
        this.data = data;
    }

    public void responder(Humor humor, String observacao, LocalDateTime momento) {
        this.humor = humor;
        this.observacao = observacao;
        this.registradoEm = momento;
    }

    public Long getId() {
        return id;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public LocalDate getData() {
        return data;
    }

    public Humor getHumor() {
        return humor;
    }

    public String getObservacao() {
        return observacao;
    }

    public LocalDateTime getRegistradoEm() {
        return registradoEm;
    }
}
