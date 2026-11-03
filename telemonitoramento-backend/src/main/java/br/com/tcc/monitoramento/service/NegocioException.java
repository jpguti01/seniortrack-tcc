package br.com.tcc.monitoramento.service;

// Erro de validacao de regra de negocio (ex: paciente nao vinculado, limiar
// invalido). O GlobalExceptionHandler converte isso em HTTP 400, diferente de
// uma excecao inesperada (bug), que deve continuar virando HTTP 500.
public class NegocioException extends RuntimeException {
    public NegocioException(String mensagem) {
        super(mensagem);
    }
}
