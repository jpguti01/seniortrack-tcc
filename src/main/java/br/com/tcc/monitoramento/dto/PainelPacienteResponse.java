package br.com.tcc.monitoramento.dto;

import java.util.List;

// Pendencias do dia de um paciente para o painel do cuidador, em uma unica
// consulta: pedidos de SOS em aberto, doses sem confirmacao e o check-in de hoje.
public record PainelPacienteResponse(Long pacienteId, List<ChamadoSosResponse> sosPendentes,
                                     int dosesAtrasadasHoje, int dosesPrevistasHoje,
                                     CheckinBemEstarResponse checkinHoje) {
}
