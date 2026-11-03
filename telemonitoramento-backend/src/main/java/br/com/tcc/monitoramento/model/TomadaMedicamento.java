package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Situacao de uma dose prevista (remedio + dia + horario). TOMADO quando o
 * paciente confirma; ATRASADO quando a verificacao automatica encontra a dose
 * sem confirmacao 30 minutos depois do horario e avisa o cuidador. Se o
 * paciente confirmar depois, a mesma linha passa para TOMADO.
 */
@Entity
@Table(name = "tb_tomada_medicamento",
        uniqueConstraints = @UniqueConstraint(columnNames = {"medicamento_id", "data", "horario"}))
public class TomadaMedicamento {

    public enum Status {
        TOMADO, ATRASADO
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "medicamento_id")
    private Medicamento medicamento;

    @Column(nullable = false)
    private LocalDate data;

    @Column(nullable = false)
    private LocalTime horario;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Status status;

    @Column(name = "confirmada_em")
    private LocalDateTime confirmadaEm;

    @Column(name = "cuidador_avisado_em")
    private LocalDateTime cuidadorAvisadoEm;

    public TomadaMedicamento() {
    }

    public TomadaMedicamento(Medicamento medicamento, LocalDate data, LocalTime horario, Status status) {
        this.medicamento = medicamento;
        this.data = data;
        this.horario = horario;
        this.status = status;
    }

    public void confirmar(LocalDateTime momento) {
        this.status = Status.TOMADO;
        this.confirmadaEm = momento;
    }

    public Long getId() {
        return id;
    }

    public Medicamento getMedicamento() {
        return medicamento;
    }

    public LocalDate getData() {
        return data;
    }

    public LocalTime getHorario() {
        return horario;
    }

    public Status getStatus() {
        return status;
    }

    public LocalDateTime getConfirmadaEm() {
        return confirmadaEm;
    }

    public LocalDateTime getCuidadorAvisadoEm() {
        return cuidadorAvisadoEm;
    }

    public void setCuidadorAvisadoEm(LocalDateTime cuidadorAvisadoEm) {
        this.cuidadorAvisadoEm = cuidadorAvisadoEm;
    }
}
