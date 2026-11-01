package br.com.tcc.monitoramento.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;

import java.time.LocalDateTime;

/**
 * Campos comuns de autenticacao compartilhados por Paciente e Cuidador (RF01, RF02).
 * E' @MappedSuperclass (nao @Entity) para que cada subclasse continue com sua
 * propria tabela (tb_paciente, tb_cuidador) em vez de herança single-table.
 */
@MappedSuperclass
public abstract class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    protected Long id;

    @Column(nullable = false, length = 100)
    protected String nome;

    @Column(nullable = false, unique = true, length = 160)
    protected String email;

    @Column(name = "senha_hash", nullable = false)
    protected String senhaHash;

    @Column(name = "criado_em", nullable = false, updatable = false)
    protected LocalDateTime criadoEm;

    protected Usuario() {
    }

    protected Usuario(String nome, String email, String senhaHash) {
        this.nome = nome;
        this.email = email;
        this.senhaHash = senhaHash;
        this.criadoEm = LocalDateTime.now();
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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    // Nunca deve aparecer em uma resposta JSON da API, nem mesmo o hash.
    @JsonIgnore
    public String getSenhaHash() {
        return senhaHash;
    }

    public void setSenhaHash(String senhaHash) {
        this.senhaHash = senhaHash;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
