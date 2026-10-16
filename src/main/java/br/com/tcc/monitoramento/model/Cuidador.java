package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

// atributos

@Entity // transformando em tabela
@Table(name = "tb_cuidador") // nome da tabela
public class Cuidador {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String nome;
    private int idade;
    private String telefone;

    @OneToMany(mappedBy = "cuidador", cascade = CascadeType.ALL)
    private List<Paciente> pacientes = new ArrayList<>();


    public Cuidador() {
    } // construtor vazio JPA

    //Construtor
    public Cuidador(String nome, int idade, String telefone) {
        this.nome = nome;
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

    public void checarRegistroPaciente(Paciente paciente) {
        paciente.analisarRegistros();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
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


    public List<Paciente> getPacientes() {
        return pacientes;
    }

    public void setPacientes(List<Paciente> pacientes) {
        this.pacientes = pacientes;
    }
}


