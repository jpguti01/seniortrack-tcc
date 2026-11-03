package br.com.tcc.monitoramento.dto;

import br.com.tcc.monitoramento.model.ChamadoSos;

import java.time.LocalDateTime;

// Resposta enxuta do chamado SOS, sem expor a entidade Paciente inteira.
public record ChamadoSosResponse(Long id, Long pacienteId, String pacienteNome, LocalDateTime criadoEm,
                                 boolean atendido, LocalDateTime atendidoEm) {

    public ChamadoSosResponse(ChamadoSos chamado) {
        this(chamado.getId(), chamado.getPaciente().getId(), chamado.getPaciente().getNome(),
                chamado.getCriadoEm(), chamado.isAtendido(), chamado.getAtendidoEm());
    }
}
