package br.com.tcc.monitoramento.dto;

import br.com.tcc.monitoramento.model.SolicitacaoVinculo;

import java.time.LocalDateTime;

// Resposta enxuta para o paciente ver quem está pedindo vínculo - evita
// expor a entidade Cuidador/Paciente inteira sem necessidade.
public class SolicitacaoVinculoResponse {

    private final Long id;
    private final Long cuidadorId;
    private final String cuidadorNome;
    private final LocalDateTime criadoEm;

    public SolicitacaoVinculoResponse(SolicitacaoVinculo solicitacao) {
        this.id = solicitacao.getId();
        this.cuidadorId = solicitacao.getCuidador().getId();
        this.cuidadorNome = solicitacao.getCuidador().getNome();
        this.criadoEm = solicitacao.getCriadoEm();
    }

    public Long getId() {
        return id;
    }

    public Long getCuidadorId() {
        return cuidadorId;
    }

    public String getCuidadorNome() {
        return cuidadorNome;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
