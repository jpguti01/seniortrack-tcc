package br.com.tcc.monitoramento.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

// Gerado automaticamente pelo MotorRegrasService quando um RegistroSinalVital
// fica fora do limiar configurado pelo cuidador (RF09).
@Entity
@Table(name = "tb_alerta")
public class Alerta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String mensagem;

    @Column(name = "data_hora", nullable = false)
    private LocalDateTime dataHora;

    @Column(nullable = false)
    private boolean resolvido;

    // Cada registro de sinal vital gera no maximo um alerta.
    @OneToOne
    @JoinColumn(name = "registro_sinal_vital_id", nullable = false, unique = true)
    private RegistroSinalVital registroSinalVital;

    public Alerta() {
    }

    public Alerta(String mensagem, RegistroSinalVital registroSinalVital) {
        this.mensagem = mensagem;
        this.registroSinalVital = registroSinalVital;
        this.dataHora = LocalDateTime.now();
        this.resolvido = false;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMensagem() {
        return mensagem;
    }

    public void setMensagem(String mensagem) {
        this.mensagem = mensagem;
    }

    public LocalDateTime getDataHora() {
        return dataHora;
    }

    public void setDataHora(LocalDateTime dataHora) {
        this.dataHora = dataHora;
    }

    public boolean isResolvido() {
        return resolvido;
    }

    public void setResolvido(boolean resolvido) {
        this.resolvido = resolvido;
    }

    public RegistroSinalVital getRegistroSinalVital() {
        return registroSinalVital;
    }

    public void setRegistroSinalVital(RegistroSinalVital registroSinalVital) {
        this.registroSinalVital = registroSinalVital;
    }
}
