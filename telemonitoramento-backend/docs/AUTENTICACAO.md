# Acesso acessível no SeniorTrack

A tela de login mantém e-mail e senha e acrescenta acesso por celular, recuperação
de senha por mensagens, Google e proteção biométrica da sessão salva. O perfil
selecionado é enviado à API: uma conta de paciente não entra como cuidador.

## SMS e WhatsApp

Configure um serviço **Twilio Verify** com códigos de **6 dígitos**, validade de
10 minutos e os canais SMS e WhatsApp habilitados. No processo do backend, defina:

```powershell
$env:TWILIO_ACCOUNT_SID = '<Account SID>'
$env:TWILIO_AUTH_TOKEN = '<Auth Token>'
$env:TWILIO_VERIFY_SERVICE_SID = '<Verify Service SID>'
```

As credenciais ficam exclusivamente no servidor. Consulte a documentação oficial
de [Verifications](https://www.twilio.com/docs/verify/api/verification),
[Verification Check](https://www.twilio.com/docs/verify/api/verification-check) e
[proteção contra abuso](https://www.twilio.com/docs/verify/preventing-toll-fraud).
Configure também os limites do serviço no Twilio para o volume esperado.

Fluxos:

- `GET /auth/opcoes`: informa quais integrações estão configuradas.
- `POST /auth/codigo/solicitar`: recebe `telefone`, `perfil` (`PACIENTE` ou
  `CUIDADOR`), `canal` (`sms` ou `whatsapp`) e `finalidade` (`login` ou
  `recuperacao`). Retorna um identificador opaco `desafio`, nunca o código.
- `POST /auth/codigo/confirmar`: recebe `desafio` e `codigo` e retorna a sessão.
- `POST /auth/senha/recuperar`: recebe `desafio`, `codigo` e `novaSenha`; altera o
  hash BCrypt, invalida os JWT anteriores e retorna uma nova sessão.

O celular deve identificar uma única conta no perfil selecionado. Números
compartilhados por várias contas exigem login por e-mail e senha. A API aceita DDD
com número nacional ou `+55`, inclusive com máscara, e normaliza os novos cadastros.
CPF não faz parte do modelo atual e não é usado para autenticação.

Desafios são persistidos no banco, expiram em 10 minutos, permitem até 5 tentativas
e só podem ser usados uma vez. É necessário aguardar 60 segundos para reenviar;
um novo envio invalida o desafio anterior, inclusive entre perfis/finalidades.
As respostas de solicitação não confirmam se o celular existe no cadastro.
Reiniciar o backend não elimina os limites de tentativas já persistidos.

## Google

Crie um cliente OAuth do tipo **aplicativo Web** no Google Cloud e use o mesmo ID:

```powershell
# Backend
$env:GOOGLE_CLIENT_ID = '<client-id>.apps.googleusercontent.com'

# Frontend Web (na pasta telemonitoramento-frontend)
flutter run -d chrome --web-port=5173 --dart-define=GOOGLE_CLIENT_ID='<client-id>.apps.googleusercontent.com'
```

Cadastre as origens autorizadas, incluindo o endereço/porta usados localmente.
No Android, configure também o cliente Android com o package
`br.com.tcc.telemonitoramento_app` e a impressão SHA-1 do certificado usado para
assinar o aplicativo. O ID Web é enviado como `serverClientId`.

O navegador usa o botão oficial do Google Identity Services. A API valida a
assinatura, audiência, emissor e validade do **ID token** e exige e-mail verificado.
O usuário já precisa ter uma conta SeniorTrack no perfil selecionado. O vínculo
automático por e-mail é aceito para Gmail e Google Workspace verificado, onde o
Google é autoridade sobre o endereço. Outros provedores continuam usando senha
ou código. Não há criação automática de contas pelo Google.

Referências: [Google Sign-In no Flutter](https://pub.dev/packages/google_sign_in/versions/6.3.0),
[botão para Web](https://pub.dev/packages/google_sign_in_web/versions/0.12.4+4) e
[verificação no servidor](https://developers.google.com/identity/sign-in/web/backend-auth).

## Biometria

A opção é exibida somente em aparelhos compatíveis com biometria cadastrada.
O usuário escolhe proteger o acesso neste aparelho e confirma sua identidade.
O aplicativo guarda o JWT e os dados da sessão no armazenamento seguro; não
guarda a senha nem captura dados biométricos. A biometria é validada pelo sistema.

Ao reabrir ou enviar o aplicativo para segundo plano, a sessão protegida é
bloqueada e as rotas sobrepostas são fechadas. Para desbloquear, a biometria precisa
ser confirmada e o JWT ainda precisa ser aceito em `GET /sessao`. Falha de conexão
mantém o bloqueio. Tokens expirados/revogados exigem novo acesso. Sair da conta
apaga a sessão e desativa sua proteção biométrica.

O runner Android foi preparado com `FlutterFragmentActivity`, permissão
`USE_BIOMETRIC` e tema AppCompat. A autenticação real deve ser validada em aparelho
físico. Web e Windows não oferecem este botão. O repositório ainda não tem runner
iOS: para distribuir no iPhone, crie/configure o runner em macOS e adicione
`NSFaceIDUsageDescription` ao `Info.plist`, além da configuração OAuth iOS.
Referência: [local_auth 2.3.0](https://pub.dev/packages/local_auth/versions/2.3.0).

## Convite do cuidador

Em **Minha conta → Convidar meu cuidador**, o paciente gera um código e QR Code.
Compartilhar o convite concede o vínculo à pessoa que usá-lo no cadastro. O código
tem 20 caracteres, validade de 24 horas e uso único. Apenas seu hash SHA-256 fica
no banco. Gerar outro convite invalida o anterior.

O cuidador informa o código no cadastro; o campo é opcional. O QR contém o mesmo
código, que pode ser lido pela câmera/leitor do celular e copiado para o formulário.
Não há leitor de câmera embutido no app. Cadastro e consumo do convite ocorrem na
mesma transação: convite inválido não deixa uma conta parcialmente criada.
Um convite não substitui um cuidador já vinculado. O fluxo anterior de solicitação
por e-mail com aprovação do paciente continua disponível.

## Configuração e validação

Sem credenciais externas, a API informa as opções como desabilitadas e a interface
mantém e-mail/senha disponíveis. Não há códigos fictícios nem simulação de login.
As novas tabelas (`tb_desafio_acesso` e `tb_convite_cuidador`) e a coluna
`versao_sessao` são criadas pela configuração de desenvolvimento `ddl-auto=update`.
Em ambientes com migrações controladas, inclua essas alterações no processo de deploy.

```powershell
# Backend: configuração leve para máquinas com pouca memória livre
$env:MAVEN_OPTS = '-Xmx256m -XX:MaxMetaspaceSize=192m -XX:ActiveProcessorCount=2'
.\mvnw.cmd test -q '-DforkCount=0'

# Frontend
flutter analyze
flutter test --concurrency=1
flutter build web
```

Os testes automatizados não enviam SMS/WhatsApp, não usam contas Google reais e
não executam sensores biométricos físicos. Os provedores devem ser validados com
credenciais de teste em um ambiente configurado antes de disponibilizar os canais.
