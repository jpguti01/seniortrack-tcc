package br.com.tcc.monitoramento.dto;

import br.com.tcc.monitoramento.model.CheckinBemEstar;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record CheckinBemEstarResponse(Long id, LocalDate data, String humor, String observacao,
                                      LocalDateTime registradoEm) {

    public CheckinBemEstarResponse(CheckinBemEstar checkin) {
        this(checkin.getId(), checkin.getData(), checkin.getHumor().name(), checkin.getObservacao(),
                checkin.getRegistradoEm());
    }
}
