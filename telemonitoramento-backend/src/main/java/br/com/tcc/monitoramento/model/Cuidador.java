package br.com.tcc.monitoramento.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

// atributos

@Entity // transformando em tabela
@Table(name = "tb_cuidador") // nome da tabela
public class Cuidador extends Usuario {

    private int idade;
    private String telefone;

    // Token do Firebase Cloud Messaging do dispositivo do cuidador, usado pelo
    // NotificacaoService para enviar o alerta push (RF09). Atualizado pelo app
    // Flutter sempre que o token for renovado pelo Firebase.
    @Column(name = "token_fcm")
    private String tokenFcm;

    @OneToMany(mappedBy = "cuidador", cascade = CascadeType.ALL)
    private List<Paciente> pacientes = new ArrayList<>();


    public Cuidador() {
    } // construtor vazio JPA

    //Construtor
    public Cuidador(String nome, String email, String senhaHash, int idade, String telefone) {
        super(nome, email, senhaHash);
        this.idade = idade;
        this.telefone = telefone;
    }


    //Métodos

    public void adicionarPaciente(Paciente paciente){
        paciente.setCuidador(this);
        pacientes.add(paciente);
    }

    public void definirLimiarPaciente(Paciente paciente, LimiarSeguranca limiarSeguranca) {
        paciente.adicionarAListaLimiarSegurancaPaciente(limiarSeguranca);

    }

    public String getTokenFcm() {
        return tokenFcm;
    }

    public void setTokenFcm(String tokenFcm) {
        this.tokenFcm = tokenFcm;
    }

    public int getIdade() {
        return idade;
    }

    public void setIdade(int idade) {
        this.idade = idade;
    }

    public String getTelefone() {
        return telefone;
    }

    public void setTelefone(String telefone) {
        this.telefone = telefone;
    }


    // Ignorado no JSON para nao entrar em loop infinito com Paciente.cuidador.
    // Use GET /pacientes (ou um endpoint dedicado) para listar os pacientes de um cuidador.
    @JsonIgnore
    public List<Paciente> getPacientes() {
        return pacientes;
    }

    public void setPacientes(List<Paciente> pacientes) {
        this.pacientes = pacientes;
    }
}


