package br.com.tcc.monitoramento.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// RF01: dados de cadastro de um paciente.
public class CadastroPacienteRequest {

    @NotBlank(message = "O nome e' obrigatorio")
    private String nome;

    @NotBlank(message = "O e-mail e' obrigatorio")
    @Email(message = "E-mail invalido")
    private String email;

    @NotBlank(message = "A senha e' obrigatoria")
    @Size(min = 8, message = "A senha deve ter pelo menos 8 caracteres")
    private String senha;

    private int idade;
    private String telefone;

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
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
}
