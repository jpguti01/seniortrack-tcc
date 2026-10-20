package br.com.tcc.monitoramento.service;

import br.com.tcc.monitoramento.model.LimiarSeguranca;
import br.com.tcc.monitoramento.model.RegistroSinalVital;
import br.com.tcc.monitoramento.repository.CuidadorRepository;
import br.com.tcc.monitoramento.repository.LimiarSegurancaRepository;
import br.com.tcc.monitoramento.repository.PacienteRepository;
import br.com.tcc.monitoramento.repository.RegistroSinalVitalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MotorRegrasService {

    private PacienteRepository pacienteRepository;
    private CuidadorRepository cuidadorRepository;
    private LimiarSegurancaRepository limiarSegurancaRepository;
    private RegistroSinalVitalRepository registroSinalVitalRepository;


    public MotorRegrasService(LimiarSegurancaRepository limiarSegurancaRepository){
        this.limiarSegurancaRepository = limiarSegurancaRepository;
    }

    public void analisarRegistro(LimiarSeguranca limiarSeguranca, RegistroSinalVital registroSinalVital){
        LimiarSeguranca limiar = limiarSeguranca;
        RegistroSinalVital registro = registroSinalVital;


        if (registro.getValorSinalVital() > limiar.getValorMax()){

            //Manda a notificação pro celular
        }

       else if (registro.getValorSinalVital() < limiar.getValorMin()){

            //Manda a notificação pro celular
        }

        else {
            // valor ok
        }

    }







}
