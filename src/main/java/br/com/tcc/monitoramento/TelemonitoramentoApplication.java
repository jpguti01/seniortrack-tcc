package br.com.tcc.monitoramento;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

// @EnableScheduling: verificacao periodica de doses de remedio sem confirmacao.
@SpringBootApplication
@EnableScheduling
public class TelemonitoramentoApplication {

    public static void main(String[] args) {
        SpringApplication.run(TelemonitoramentoApplication.class, args);
    }
}