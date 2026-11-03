package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.model.RegistroSinalVital.TipoSinalVital;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class RegistroSinalVitalService {

    private final RegistroSinalVitalRepository registroSinalVitalRepository;
    private final PacienteRepository pacienteRepository;
    private final MotorRegrasService motorRegrasService;


    public RegistroSinalVitalService(RegistroSinalVitalRepository registroSinalVitalRepository,
                                      PacienteRepository pacienteRepository,
                                      MotorRegrasService motorRegrasService) {
        this.registroSinalVitalRepository = registroSinalVitalRepository;
        this.pacienteRepository = pacienteRepository;
        this.motorRegrasService = motorRegrasService;
    }


    // RF06, UC-02: persiste o registro e, em seguida, aciona o motor de regras (UC-03).
    public RegistroSinalVital salvar(RegistroSinalVital registroSinalVital){

        if (registroSinalVital.getPaciente() == null || registroSinalVital.getPaciente().getId() == null)
            throw new NegocioException("Paciente não encontrado, ou não cadastrado");

        if (!pacienteRepository.existsById(registroSinalVital.getPaciente().getId()))
            throw new NegocioException("Paciente não encontrado, ou não cadastrado");

        // A data/hora da coleta e' sempre definida pelo servidor (RF06), nunca pelo cliente.
        registroSinalVital.setHoraRegistro(LocalDateTime.now());

        RegistroSinalVital salvo = registroSinalVitalRepository.save(registroSinalVital);

        motorRegrasService.analisarRegistro(salvo);

        return salvo;
    }

    // RF10: historico completo do paciente, mais recente primeiro.
    public List<RegistroSinalVital> listarPorPaciente(Long pacienteId) {
        return registroSinalVitalRepository.findByPacienteIdOrderByHoraRegistroDesc(pacienteId);
    }

    // RF11: filtro por tipo de sinal e/ou periodo.
    public List<RegistroSinalVital> filtrarPorPaciente(Long pacienteId, TipoSinalVital tipo,
                                                         LocalDateTime desde, LocalDateTime ate) {
        if (desde != null && ate != null) {
            return registroSinalVitalRepository.findByPacienteIdAndHoraRegistroBetweenOrderByHoraRegistroDesc(pacienteId, desde, ate);
        }
        if (tipo != null) {
            return registroSinalVitalRepository.findByPacienteIdAndTipoSinalVitalOrderByHoraRegistroDesc(pacienteId, tipo);
        }
        return listarPorPaciente(pacienteId);
    }

    // RF07: edita o ultimo lancamento do paciente (e so ele), corrigindo um erro de digitacao.
    public RegistroSinalVital editarUltimo(Long pacienteId, double novoValor) {
        RegistroSinalVital ultimo = buscarUltimo(pacienteId);
        ultimo.setValorSinalVital(novoValor);
        return registroSinalVitalRepository.save(ultimo);
    }

    // RF07: exclui o ultimo lancamento do paciente (e so ele).
    public void excluirUltimo(Long pacienteId) {
        RegistroSinalVital ultimo = buscarUltimo(pacienteId);
        registroSinalVitalRepository.delete(ultimo);
    }

    private RegistroSinalVital buscarUltimo(Long pacienteId) {
        return registroSinalVitalRepository.findFirstByPacienteIdOrderByHoraRegistroDesc(pacienteId)
                .orElseThrow(() -> new NegocioException("O paciente ainda não possui nenhum registro de sinal vital."));
    }
}
