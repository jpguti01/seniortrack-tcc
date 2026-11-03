package br.com.tcc.monitoramento.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;

// Cadastro/edicao de um remedio pelo cuidador. Horarios no formato "HH:mm".
// A foto e' uma data URL (data:image/jpeg;base64,...) ou nula.
public record MedicamentoRequest(
        @NotBlank(message = "Informe o nome do remédio.") @Size(max = 100) String nome,
        @Size(max = 60) String dosagem,
        @Size(max = 255) String instrucoes,
        @NotEmpty(message = "Informe ao menos um horário.") @Size(max = 8, message = "Use no máximo 8 horários.") List<String> horarios,
        String foto) {
}
