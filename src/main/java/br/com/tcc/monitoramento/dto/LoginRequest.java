package br.com.tcc.monitoramento.dto;

import jakarta.validation.constraints.NotBlank;

public class LoginRequest {

    @NotBlank(message = "O e-mail e' obrigatorio")
    private String email;

    @NotBlank(message = "A senha e' obrigatoria")
    private String senha;

    private br.com.tcc.monitoramento.security.TipoUsuario perfil;
    public br.com.tcc.monitoramento.security.TipoUsuario getPerfil() { return perfil; }
    public void setPerfil(br.com.tcc.monitoramento.security.TipoUsuario perfil) { this.perfil = perfil; }

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
}
