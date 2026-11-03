package br.com.tcc.monitoramento.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Remedio da rotina do paciente, cadastrado pelo cuidador vinculado. O
 * paciente so confirma cada dose ("Tomei"). Desativar um remedio preserva o
 * historico de doses para o relatorio de adesao.
 */
@Entity
@Table(name = "tb_medicamento")
public class Medicamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    @Column(nullable = false, length = 100)
    private String nome;

    @Column(length = 60)
    private String dosagem;

    @Column(length = 255)
    private String instrucoes;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "tb_medicamento_horario", joinColumns = @JoinColumn(name = "medicamento_id"))
    @Column(name = "horario", nullable = false)
    @OrderBy
    private List<LocalTime> horarios = new ArrayList<>();

    // Foto do comprimido ou da caixa como data URL (data:image/jpeg;base64,...).
    @Column(name = "foto", columnDefinition = "text")
    private String foto;

    @Column(nullable = false)
    private boolean ativo = true;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    @Column(name = "desativado_em")
    private LocalDateTime desativadoEm;

    public Medicamento() {
    }

    public Medicamento(Paciente paciente) {
        this.paciente = paciente;
        this.criadoEm = LocalDateTime.now();
    }

    // Uma dose so e' prevista enquanto o remedio estava cadastrado e ativo.
    public boolean vigenteEm(LocalDateTime momento) {
        return !momento.isBefore(criadoEm) && (desativadoEm == null || momento.isBefore(desativadoEm));
    }

    public void desativar() {
        this.ativo = false;
        this.desativadoEm = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    @JsonIgnore
    public Paciente getPaciente() {
        return paciente;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getDosagem() {
        return dosagem;
    }

    public void setDosagem(String dosagem) {
        this.dosagem = dosagem;
    }

    public String getInstrucoes() {
        return instrucoes;
    }

    public void setInstrucoes(String instrucoes) {
        this.instrucoes = instrucoes;
    }

    public List<LocalTime> getHorarios() {
        return horarios;
    }

    public void setHorarios(List<LocalTime> horarios) {
        this.horarios.clear();
        this.horarios.addAll(horarios);
    }

    public String getFoto() {
        return foto;
    }

    public void setFoto(String foto) {
        this.foto = foto;
    }

    public boolean isAtivo() {
        return ativo;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }

    public LocalDateTime getDesativadoEm() {
        return desativadoEm;
    }
}
