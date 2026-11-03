package br.com.tcc.monitoramento.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.FileSystemResource;

import jakarta.annotation.PostConstruct;
import java.io.FileNotFoundException;
import java.io.InputStream;

/**
 * Inicializa o Firebase Admin SDK (usado apenas para notificacoes push via FCM,
 * ver NotificacaoService). A credencial NAO fica no repositorio: o caminho do
 * arquivo e' informado pela variavel de ambiente FIREBASE_CREDENTIALS_PATH.
 *
 * Em desenvolvimento local, copie firebase-service-account.json.example para um
 * arquivo fora do controle de versao e aponte a variavel de ambiente para ele.
 * Se a variavel nao estiver definida, as notificacoes push ficam desativadas
 * (o restante da aplicacao continua funcionando normalmente).
 */
@Configuration
public class FireBaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FireBaseConfig.class);

    @Value("${firebase.credentials.path:}")
    private String credentialsPath;

    @PostConstruct
    public void inicializar() {
        if (credentialsPath == null || credentialsPath.isBlank()) {
            log.warn("FIREBASE_CREDENTIALS_PATH nao configurada: notificacoes push via FCM ficam desativadas.");
            return;
        }

        try (InputStream serviceAccount = new FileSystemResource(credentialsPath).getInputStream()) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                log.info("Firebase inicializado com sucesso a partir de {}", credentialsPath);
            } else {
                log.debug("Firebase ja estava inicializado.");
            }
        } catch (FileNotFoundException e) {
            log.error("Arquivo de credenciais do Firebase nao encontrado em '{}'. Notificacoes push desativadas.", credentialsPath);
        } catch (Exception e) {
            log.error("Falha ao inicializar o Firebase. Notificacoes push desativadas.", e);
        }
    }
}