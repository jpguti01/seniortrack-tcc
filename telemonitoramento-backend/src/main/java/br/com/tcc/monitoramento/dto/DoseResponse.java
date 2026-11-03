package br.com.tcc.monitoramento.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

// Uma dose prevista do dia, com o status calculado: TOMADO, PENDENTE ou ATRASADO
// (sem confirmacao 30 minutos depois do horario).
public record DoseResponse(Long medicamentoId, String nome, String dosagem, String instrucoes, LocalDate data,
                           String horario, String status, LocalDateTime confirmadaEm) {
}
