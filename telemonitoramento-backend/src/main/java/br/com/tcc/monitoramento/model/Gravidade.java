package br.com.tcc.monitoramento.model;

/**
 * Gravidade de uma medicao fora da faixa configurada pelo cuidador.
 * ATENCAO: levemente fora da faixa. CRITICO: muito fora da faixa (ver
 * service.ClassificadorGravidade). Uma medicao dentro da faixa nao gera alerta,
 * por isso nao ha um valor "NORMAL" aqui.
 */
public enum Gravidade {
    ATENCAO,
    CRITICO
}
