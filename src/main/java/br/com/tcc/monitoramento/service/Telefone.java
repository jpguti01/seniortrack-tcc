package br.com.tcc.monitoramento.service;

public final class Telefone {
    private Telefone() {}

    public static String normalizar(String valor) {
        String numero = valor == null ? "" : valor.replaceAll("\\D", "");
        if (numero.length() == 10 || numero.length() == 11) numero = "55" + numero;
        if (!numero.matches("55[1-9][0-9]{9,10}")) {
            throw new IllegalArgumentException("Informe seu celular com DDD, por exemplo (11) 99999-9999.");
        }
        return "+" + numero;
    }
}
