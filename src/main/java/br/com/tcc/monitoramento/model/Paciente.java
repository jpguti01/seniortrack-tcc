package br.com.tcc.monitoramento.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import jakarta.persistence.*;



@Entity //Transformando em Tabela
@Table(name = "tb_paciente") // atribuindo um nome para tabela
public class Paciente extends Usuario {

    private int idade;
    private String telefone;
    private LocalDate dataNascimento;

    @ManyToOne
    @JoinColumn(name = "cuidador_id") // Cria a coluna de chave estrangeira no PostgreSQL
    private Cuidador cuidador;


    @OneToMany(mappedBy = "paciente", cascade = CascadeType.ALL)// 1 Paciente para muitos  Registros de sinais vitais
    private List<RegistroSinalVital> historicoRegistros = new ArrayList<>();

    @OneToMany(mappedBy = "paciente", cascade = CascadeType.ALL)
    private List<LimiarSeguranca> limiarSegurancaPaciente = new ArrayList<>();


    public Paciente() {} // Construtor Vazio (Obrigatorio Para o Jpa Conseguir Instanciar)

    public Paciente(String nome, String email, String senhaHash, int idade, String telefone) {
        super(nome, email, senhaHash);
        this.idade = idade;
        this.telefone = telefone;
    }

    //Metodos

    // Adiciona a lista de limiar do paciente um objeto limiar -- obs: Não utilizamos o metodo, ele é acionado pelo metodo da classe Cuidador - definirLimiarPaciente
    public void adicionarAListaLimiarSegurancaPaciente(LimiarSeguranca limiarSeguranca){
        limiarSeguranca.setPaciente(this);
        this.limiarSegurancaPaciente.add(limiarSeguranca);

    }

    public void adicionarRegistro(RegistroSinalVital registroSinalVital){
        registroSinalVital.setPaciente(this);
        this.historicoRegistros.add(registroSinalVital);
    }

    /// GETTERS E SETTERS

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

    public LocalDate getDataNascimento() {
        return dataNascimento;
    }

    public void setDataNascimento(LocalDate dataNascimento) {
        this.dataNascimento = dataNascimento;
    }

    // Ignorados no JSON para nao entrar em loop infinito com as referencias de
    // volta para Paciente (RegistroSinalVital.paciente, LimiarSeguranca.paciente).
    // Use os endpoints dedicados (/registrosinalvital/paciente/{id} e
    // /limiarseguranca/paciente/{id}) para essas listas.
    @JsonIgnore
    public List<RegistroSinalVital> getHistoricoRegistros() {
        return historicoRegistros;
    }

    public void setHistoricoRegistros(List<RegistroSinalVital> historicoRegistros) {
        this.historicoRegistros = historicoRegistros;
    }

    @JsonIgnore
    public List<LimiarSeguranca> getLimiarSegurancaPaciente() {
        return limiarSegurancaPaciente;
    }

    public void setLimiarSegurancaPaciente(List<LimiarSeguranca> limiarSegurancaPaciente) {
        this.limiarSegurancaPaciente = limiarSegurancaPaciente;
    }

    public Cuidador getCuidador() {
        return cuidador;
    }

    public void setCuidador(Cuidador cuidador) {
        this.cuidador = cuidador;
    }
}


