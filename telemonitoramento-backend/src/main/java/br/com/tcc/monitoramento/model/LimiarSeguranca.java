package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

@Entity
@Table(name = "tb_limiar_seguranca")
public class LimiarSeguranca {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    private RegistroSinalVital.TipoSinalVital tipoSinalVital;
    private double valorMax;
    private double valorMin;

    @ManyToOne
    @JoinColumn(name = "paciente_id") // Cria a FK para Paciente
    private Paciente paciente;

    @ManyToOne
    @JoinColumn(name = "cuidador_id") // Cria a FK para Cuidador
    private Cuidador cuidador;


    public LimiarSeguranca() {}


 public LimiarSeguranca(double valorMax, double valorMin,  RegistroSinalVital.TipoSinalVital tipoSinalVital) {
     this.valorMax = valorMax;
     this.valorMin = valorMin;
     this.tipoSinalVital = tipoSinalVital;

 }


 //metodos

    public void setValorMax(double valorMax){
        this.valorMax = valorMax;
    }

    public void setValorMin(double valorMin){
        this.valorMin = valorMin;
    }


    public RegistroSinalVital.TipoSinalVital getTipoSinalVital() {
     return tipoSinalVital;
    }
    public double getValorMax() {
        return valorMax;
    }
    public double getValorMin() {
     return valorMin;
    }

    public void setPaciente(Paciente paciente){
        this.paciente = paciente;
 }

    public Paciente getPaciente() {
     return paciente;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setTipoSinalVital(RegistroSinalVital.TipoSinalVital tipoSinalVital) {
        this.tipoSinalVital = tipoSinalVital;
    }

    public Cuidador getCuidador() {
        return cuidador;
    }

    public void setCuidador(Cuidador cuidador) {
        this.cuidador = cuidador;
    }
}