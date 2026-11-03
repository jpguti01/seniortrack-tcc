package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.*;
import br.com.tcc.monitoramento.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.HexFormat;

@Service
public class ConviteCuidadorService {
    private final ConviteCuidadorRepository convites;
    private final EntityManager em;
    public ConviteCuidadorService(ConviteCuidadorRepository convites, EntityManager em) {
        this.convites = convites; this.em = em;
    }

    @Transactional
    public String gerar(Long pacienteId) {
        // Serializa geração/consumo para o mesmo paciente.
        if (em.find(Paciente.class, pacienteId, LockModeType.PESSIMISTIC_WRITE) == null) throw invalido();
        byte[] bytes = new byte[10];
        new SecureRandom().nextBytes(bytes);
        String codigo = HexFormat.of().withUpperCase().formatHex(bytes);
        ConviteCuidador convite = convites.findById(pacienteId).orElseGet(ConviteCuidador::new);
        convite.pacienteId = pacienteId;
        convite.codigoHash = hash(codigo);
        convite.expiraEm = Instant.now().plusSeconds(86400);
        convite.usado = false;
        convites.save(convite);
        return codigo;
    }

    @Transactional
    public void aceitar(String codigo, Cuidador cuidador) {
        if (codigo == null || codigo.isBlank()) return;
        String normalizado = codigo.trim().toUpperCase(java.util.Locale.ROOT).replace("-", "");
        if (!normalizado.matches("[A-F0-9]{20}")) throw invalido();
        // Consulta sem lock só para descobrir o paciente; depois sempre paciente -> convite.
        String codigoHash = hash(normalizado);
        Long pacienteId = em.createQuery("select c.pacienteId from ConviteCuidador c where c.codigoHash = :hash", Long.class)
                .setParameter("hash", codigoHash).getResultStream().findFirst().orElseThrow(this::invalido);
        Paciente paciente = em.find(Paciente.class, pacienteId, LockModeType.PESSIMISTIC_WRITE);
        ConviteCuidador convite = convites.bloquearCodigo(codigoHash).orElseThrow(this::invalido);
        if (paciente == null || convite.usado || !convite.expiraEm.isAfter(Instant.now())) throw invalido();
        if (paciente.getCuidador() != null) {
            throw new IllegalArgumentException("Este paciente já tem um cuidador. Peça um novo vínculo pelo aplicativo.");
        }
        cuidador.adicionarPaciente(paciente);
        convite.usado = true;
    }

    private String hash(String codigo) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(codigo.getBytes(StandardCharsets.UTF_8))); }
        catch (NoSuchAlgorithmException e) { throw new IllegalStateException(e); }
    }
    private IllegalArgumentException invalido() {
        return new IllegalArgumentException("Convite inválido ou expirado. Peça um novo código ao paciente ou cadastre-se sem convite.");
    }
}
