package br.com.tcc.monitoramento.dto;

// Adesao ao tratamento no periodo: doses que ja deviam ter sido tomadas
// (previstas) e quantas o paciente confirmou.
public record AdesaoResponse(Long medicamentoId, String nome, String dosagem, boolean ativo, int previstas,
                             int tomadas) {

    public int naoConfirmadas() {
        return previstas - tomadas;
    }
}
