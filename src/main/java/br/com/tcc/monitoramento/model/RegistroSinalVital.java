package br.com.tcc.monitoramento.model;


import jakarta.persistence.*;

import java.time.LocalDateTime;



@Entity  // Transformando em Tabela
@Table(name = "tb_registro_sinal_vital") // atribuindo nome a atbela
public class RegistroSinalVital {

    public enum TipoSinalVital{
        PRESSAO_ARTERIAL,
        GLICEMIA,
        PESO;};

@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

@Enumerated(EnumType.STRING)
@Column(name = "tipo_sinal", nullable = false)
    private TipoSinalVital tipoSinalVital;

@Column(name = "valor_sinal", nullable = false)
    private double valorSinalVital;

@Column(name = "hora_registro", nullable = false)
    private LocalDateTime horaRegistro;


    //associação
    @ManyToOne
    @JoinColumn(name = "paciente_id")
    private Paciente paciente;

    ///Construtor
    public RegistroSinalVital(){

    }




//setter e Getters

public TipoSinalVital getTipoSinalVital() {
    return tipoSinalVital;
}

public double getValorSinalVital() {
        return valorSinalVital;
}

public void setTipoSinalVital(TipoSinalVital tipoSinalVital) {
        this.tipoSinalVital = tipoSinalVital;
}

public LocalDateTime getHoraRegistro() {
        return horaRegistro;
}



    public long getId() {
        return id;
    }


    public void setId(long id) {
        this.id = id;
    }


    public Paciente getPaciente() {
        return paciente;
    }

    public void setPaciente(Paciente paciente) {
        this.paciente = paciente;
    }

}

