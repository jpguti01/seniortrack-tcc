package br.com.tcc.monitoramento.dto;

import br.com.tcc.monitoramento.model.Medicamento;

import java.time.format.DateTimeFormatter;
import java.util.List;

public record MedicamentoResponse(Long id, String nome, String dosagem, String instrucoes, List<String> horarios,
                                  String foto, boolean ativo) {

    public static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm");

    public MedicamentoResponse(Medicamento medicamento) {
        this(medicamento.getId(), medicamento.getNome(), medicamento.getDosagem(), medicamento.getInstrucoes(),
                medicamento.getHorarios().stream().sorted().map(HORA::format).toList(),
                medicamento.getFoto(), medicamento.isAtivo());
    }
}
