package br.com.tcc.monitoramento.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

// RNF05: emissao e validacao dos tokens JWT usados pela API REST.
@Service
public class JwtService {

    private final SecretKey chave;
    private final long validadeMinutos;

    public JwtService(@Value("${jwt.secret}") String segredo,
                       @Value("${jwt.expiration-minutes}") long validadeMinutos) {
        this.chave = Keys.hmacShaKeyFor(segredo.getBytes(StandardCharsets.UTF_8));
        this.validadeMinutos = validadeMinutos;
    }

    public String gerarToken(UsuarioAutenticado usuario) {
        return gerarToken(usuario, 0);
    }

    public String gerarToken(UsuarioAutenticado usuario, int versaoSessao) {
        Date agora = new Date();
        Date expiracao = new Date(agora.getTime() + validadeMinutos * 60 * 1000);

        return Jwts.builder()
                .subject(usuario.getUsername())
                .claim("id", usuario.getId())
                .claim("tipo", usuario.getTipo().name())
                .claim("versao", versaoSessao)
                .issuedAt(agora)
                .expiration(expiracao)
                .signWith(chave)
                .compact();
    }

    public Claims validarEExtrairClaims(String token) {
        return Jwts.parser()
                .verifyWith(chave)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
