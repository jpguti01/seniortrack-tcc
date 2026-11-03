package br.com.tcc.monitoramento.model;


import jakarta.persistence.*;

import java.time.LocalDateTime;



@Entity  // Transformando em Tabela
@Table(name = "tb_registro_sinal_vital") // atribuindo nome a atbela
public class RegistroSinalVital {

    // O JSON continua usando o nome da constante (ex: "GLICEMIA"); rotulo e
    // unidade servem so para os textos das notificacoes.
    public enum TipoSinalVital{
        PRESSAO_ARTERIAL("Pressão arterial", "mmHg"),
        GLICEMIA("Glicemia", "mg/dL"),
        PESO("Peso", "kg");

        private final String rotulo;
        private final String unidade;

        TipoSinalVital(String rotulo, String unidade) {
            this.rotulo = rotulo;
            this.unidade = unidade;
        }

        public String getRotulo() {
            return rotulo;
        }

        public String getUnidade() {
            return unidade;
        }
    }

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

public void setValorSinalVital(double valorSinalVital) {
        this.valorSinalVital = valorSinalVital;
}

public void setTipoSinalVital(TipoSinalVital tipoSinalVital) {
        this.tipoSinalVital = tipoSinalVital;
}

@com.fasterxml.jackson.annotation.JsonProperty(access = com.fasterxml.jackson.annotation.JsonProperty.Access.READ_ONLY)
public LocalDateTime getHoraRegistro() {
        return horaRegistro;
}

// O horario e' sempre definido pelo servidor no momento do salvamento
// (ver RegistroSinalVitalService.salvar) para que o cliente nao possa
// forjar a data/hora da coleta; por isso o campo e' ignorado se vier no JSON.
public void setHoraRegistro(LocalDateTime horaRegistro) {
        this.horaRegistro = horaRegistro;
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

