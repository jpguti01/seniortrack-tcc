# Retomada da validação do SeniorTrack

## Acesso restaurado

O último processo deixado pelo Claude na porta 8080 apontava para
`telemonitoramento_teste`, cópia em que as senhas foram alteradas durante os
testes. O processo foi substituído por um backend usando `telemonitoramento_db`.
A conta original do cuidador voltou a autenticar e carregar seus cinco pacientes,
sem redefinir senha ou substituir históricos. Foi criado um backup local do
banco original antes da intervenção.

| Ambiente | Porta | Banco |
| --- | --- | --- |
| Aplicativo de uso local | 5050 | Acessa o backend 8080 |
| Backend original | 8080 | `telemonitoramento_db` |
| Backend de validação | 8081 | `telemonitoramento_teste` |

Use `scripts/iniciar-local.ps1` para o backend original. Para os testes, use
`scripts/iniciar-local.ps1 -Banco telemonitoramento_teste`. O script impede o
banco de testes na porta 8080 e desativa notificações externas no ambiente de
teste. Os logs ficam em `C:\TCC\.local-backups\runtime`.

## Onde a implementação parou

O histórico do projeto registra a última validação do Claude no formulário de
medicamentos, após conferir check-in, SOS e as novas abas do cuidador. Ainda
faltava fechar a confirmação “Tomei” e a exportação clínica pelo navegador.
Os pedidos posteriores sobre custos de agentes/plugins são uma tarefa distinta
e não fazem parte desta validação do produto.

## Fluxos implementados

| Objetivo | Implementação e limite |
| --- | --- |
| Estado visual das medições | Normal, atenção e crítico; texto explicativo e faixas do cuidador |
| Ajuda imediata | SOS registrado no servidor, atendimento pelo cuidador e atalhos de contato |
| Acessibilidade | Modo simples, letras maiores, leitura por voz e entrada de números por voz |
| Medicamentos | Foto, horários, cadastro pelo cuidador, confirmação pelo paciente e adesão no relatório |
| Atraso de dose | Verificação a cada minuto, com tolerância de 30 minutos; requer servidor em execução |
| Notificações externas | Adaptadores de Twilio, webhook e FCM; dependem de configuração, credenciais e dispositivo/token |
| Gráficos | Indicadores simples no modo idoso e evolução detalhada no cuidador |
| PDF clínico | Histórico, estatísticas, alertas, adesão, bem-estar e SOS; fontes locais preservam pontuação |
| Bluetooth | Leitura de perfis padrão de pressão, glicemia e peso; exige navegador e aparelho compatíveis |
| Perfis e diário | Autorização por paciente/cuidador e um check-in de bem-estar por dia |

A integração de oxímetros/SpO2 ainda não está presente no modelo atual de sinais
vitais. Também não há alarme de medicamento em segundo plano no navegador fechado.
Esses itens exigem evolução específica, além dos fluxos de rotina/atraso já
implementados. A verificação de sensores, voz e notificações reais não é substituída
pelos testes de software.

## Repetir a validação sem usar contas reais

```powershell
# Na pasta telemonitoramento-backend
./scripts/iniciar-local.ps1 -Banco telemonitoramento_teste
python -X utf8 scripts/validar-fluxos-locais.py
```

O script só usa `http://localhost:8081`, cria contas fictícias no domínio
`example.invalid` e verifica convite, vínculo, controle de acesso, medicamentos,
confirmação repetida sem duplicar a dose, adesão, check-in, SOS e histórico.
Nunca deve ser redirecionado ao banco original. A opção `--contexto` existe para
automação local do navegador; seu arquivo contém credenciais fictícias e não deve
ser publicado.

No frontend, execute `flutter analyze`, `flutter test --concurrency=1` e
`flutter build web`. A licença das fontes incorporadas está em
`assets/fonts/WorkSans-OFL.txt`.

## Preparação da publicação

O histórico mencionava GitHub e Vercel como etapa seguinte. Ainda é necessário
um endereço HTTPS público para a API Spring Boot e seu banco. Hospedar somente o
Flutter na Vercel não torna a API local acessível aos visitantes.
O build da Vercel agora exige `API_BASE_URL` com HTTPS e rejeita localhost, para
evitar publicar novamente uma tela de login sem o backend correto.
Integrações de Google/SMS/WhatsApp seguem a configuração de
[Autenticação](AUTENTICACAO.md).
