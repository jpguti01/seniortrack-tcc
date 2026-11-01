package br.com.tcc.monitoramento.dto;

// RF03: resposta devolvida apos um login bem-sucedido, para o app direcionar
// o usuario para a interface correspondente ao seu perfil.
public class TokenResponse {

    private final String token;
    private final String tipo;
    private final Long id;
    private final String nome;

    public TokenResponse(String token, String tipo, Long id, String nome) {
        this.token = token;
        this.tipo = tipo;
        this.id = id;
        this.nome = nome;
    }

    public String getToken() {
        return token;
    }

    public String getTipo() {
        return tipo;
    }

    public Long getId() {
        return id;
    }

    public String getNome() {
        return nome;
    }
}
