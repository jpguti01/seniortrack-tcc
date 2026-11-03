# SeniorTrack — roteiro da demonstração

Os dados desta apresentação são fictícios. As faixas configuradas servem apenas
para mostrar o funcionamento do software; não são recomendações clínicas.

## Contas e cenários

Continue usando os e-mails e as senhas das contas **Paciente Demo** e
**Cuidador Demo**. A preparação não altera essas credenciais.

O cuidador passa a acompanhar cinco perfis:

| Perfil | Cenário de apresentação |
| --- | --- |
| Paciente Demo original | Histórico de 30 dias, registros de hoje e alertas pendentes e resolvidos |
| Maria Helena | Histórico preenchido e nenhum alerta pendente |
| Antônio Silva | Histórico preenchido e medições fictícias fora das faixas configuradas |
| Carlos Almeida | Histórico preenchido, mas sem registros nos últimos três dias |
| Lúcia Santos | Primeiro acesso: perfil e faixas preenchidos, antes da primeira medição |

Os quatro perfis adicionais usam e-mails no domínio reservado `.invalid` e
possuem login desativado. Eles aparecem na conta do cuidador; os dois acessos
originais continuam sendo os acessos da apresentação.

Os telefones são fictícios (`(11) 00000-0000`). A preparação não envia e-mails,
mensagens, ligações ou notificações externas.

## Sequência sugerida

1. Entre na conta Paciente Demo em `http://localhost:5050`.
2. Mostre o resumo dos tipos registrados hoje e os cartões de pressão, glicemia e peso.
3. Abra um formulário de registro; um valor fictício de pressão como `120` permite mostrar a gravação.
4. Mostre os alertas, a leitura por voz e o contato do cuidador.
5. Compare os filtros de 7 e 30 dias e o filtro por sinal vital.
6. Exporte o histórico em PDF e mostre os valores, as unidades e o período escolhido.
7. Se houver uma solicitação pendente do próprio cuidador demo, demonstre o aceite ou a recusa.
   Esse pedido repete o fluxo de consentimento entre as mesmas contas; nenhuma das
   opções desfaz o vínculo que já existia. Caso o pedido já tenha sido respondido,
   use “Solicitar vínculo” na conta do cuidador, com o e-mail da conta Paciente Demo,
   para repetir a demonstração.
8. Entre na conta Cuidador Demo e mostre os cinco pacientes, os contadores e os filtros.
9. Abra o perfil de Antônio e mostre o histórico, as faixas configuradas e os alertas.
10. Resolva uma ocorrência fictícia e volte ao painel para ver a atualização.
11. Abra Carlos para demonstrar ausência de medições recentes e Lúcia para mostrar o primeiro registro.

Voz e abertura do discador dependem dos recursos do dispositivo. O PDF pode ser
salvo e compartilhado manualmente. A versão atual também inclui rotina de
medicamentos, confirmação “Tomei”, check-in de bem-estar e SOS. Esses novos fluxos
podem ser validados separadamente no banco de testes; consulte
[Estado da validação](ESTADO-VALIDACAO.md).

## Iniciar sem trocar as contas originais

Na pasta do backend, execute `./scripts/iniciar-local.ps1`. O comando usa
`telemonitoramento_db` na porta **8080**. Para recompilar e reiniciar, acrescente
`-Compilar`.

O banco `telemonitoramento_teste` usa a porta **8081**. Ele pode conter senhas e
registros fictícios distintos dos originais e não deve ser colocado na porta
8080. O script bloqueia essa combinação para preservar o acesso de demonstração.

## Atualizar os dados antes de apresentar

Com o Docker e o PostgreSQL local em execução, abra PowerShell no backend:

```powershell
./scripts/preparar-demo.ps1 `
  -PacienteEmail 'EMAIL_DA_CONTA_PACIENTE_DEMO' `
  -CuidadorEmail 'EMAIL_DA_CONTA_CUIDADOR_DEMO'
```

O script cria um backup em `C:\TCC\.local-backups` antes de gravar e executa a
carga dentro de uma transação. Para somente conferir os cenários, sem gravá-los,
adicione `-SomenteValidar`.

A carga é repetível: registros nos mesmos horários não são duplicados. Ela
preenche novas datas, mantém os registros anteriores, não reabre alertas
resolvidos e não recria uma solicitação de demonstração já respondida. Os backups
contêm dados de acesso do banco e devem permanecer locais, fora do material
compartilhado com o público.
