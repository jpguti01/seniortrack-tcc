package br.com.tcc.monitoramento.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;

@Configuration
public class FireBaseConfig {

    @PostConstruct
    public void inicializar() {
        System.out.println(">>> [DEBUG] A tentar inicializar o Firebase...");
        try {
            InputStream serviceAccount = new ClassPathResource("firebase-service-account.json").getInputStream();
            System.out.println(">>> [DEBUG] Ficheiro JSON de credenciais encontrado com sucesso!");

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase inicializado com sucesso!");
            } else {
                System.out.println(">>> [DEBUG] O Firebase já se encontrava inicializado.");
            }

        } catch (Exception e) {
            System.err.println(">>> [ERRO] Falha ao inicializar o Firebase:");
            e.printStackTrace();
        }
    }
}