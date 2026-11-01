package br.com.tcc.monitoramento.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

/**
 * Adapta Paciente ou Cuidador para o contrato UserDetails do Spring Security,
 * carregando tambem o id e o tipo de perfil (RF02) para uso nos controllers
 * (ex: restringir um paciente a ver apenas os proprios dados).
 */
public class UsuarioAutenticado implements UserDetails {

    private final Long id;
    private final String email;
    private final String senhaHash;
    private final TipoUsuario tipo;

    public UsuarioAutenticado(Long id, String email, String senhaHash, TipoUsuario tipo) {
        this.id = id;
        this.email = email;
        this.senhaHash = senhaHash;
        this.tipo = tipo;
    }

    public Long getId() {
        return id;
    }

    public TipoUsuario getTipo() {
        return tipo;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + tipo.name()));
    }

    @Override
    public String getPassword() {
        return senhaHash;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
