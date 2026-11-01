# Telemonitoramento - Backend

API REST em Spring Boot para o sistema de telemonitoramento de sinais vitais de
idosos (TCC). Arquitetura em camadas (Controller, Service, Repository, Model)
sobre PostgreSQL, com autenticação JWT e notificações push via Firebase Cloud
Messaging.

## Pré-requisitos

- Java 21
- Maven (ou use a sua IDE - o projeto foi criado no IntelliJ)
- PostgreSQL rodando localmente (ou acessível via rede)

## Configuração

Todas as credenciais são lidas de variáveis de ambiente - **nada sensível fica
no repositório**. Defina antes de rodar a aplicação (os valores abaixo são só
exemplo):

| Variável | Obrigatória | Exemplo |
|---|---|---|
| `DB_URL` | Não (default: banco local) | `jdbc:postgresql://localhost:5432/telemonitoramento_db` |
| `DB_USERNAME` | Não (default: `postgres`) | `postgres` |
| `DB_PASSWORD` | **Sim**, em qualquer ambiente real | `sua-senha-aqui` |
| `JWT_SECRET` | **Sim**, em qualquer ambiente real | uma string aleatória longa (32+ bytes) |
| `JWT_EXPIRATION_MINUTES` | Não (default: 120) | `120` |
| `FIREBASE_CREDENTIALS_PATH` | Não (sem ela, notificações push ficam desativadas) | `C:/chaves/firebase-service-account.json` |

Para o Firebase: copie `src/main/resources/firebase-service-account.json.example`,
baixe a chave real no Console do Firebase (Configurações do projeto → Contas de
serviço → Gerar nova chave privada), salve **fora do repositório** e aponte
`FIREBASE_CREDENTIALS_PATH` para esse arquivo.

## Rodando localmente

```bash
mvn spring-boot:run
```

A aplicação sobe em `http://localhost:8080`. O Hibernate cria/atualiza as
tabelas automaticamente (`spring.jpa.hibernate.ddl-auto=update`).

## Autenticação

Todos os endpoints exigem um token JWT no header `Authorization: Bearer <token>`,
exceto os de `/auth/**`.

```
POST /auth/cadastro/paciente   { nome, email, senha, idade, telefone }
POST /auth/cadastro/cuidador   { nome, email, senha, idade, telefone }
POST /auth/login               { email, senha } -> { token, tipo, id, nome }
```

## Endpoints principais

| Recurso | Endpoints |
|---|---|
| Paciente | `GET /pacientes`, `GET /pacientes/{id}`, `DELETE /pacientes/{id}` |
| Cuidador | `GET /cuidador`, `GET /cuidador/{id}`, `PUT /cuidador/{id}/token-fcm` |
| Sinal vital | `POST /registrosinalvital`, `GET /registrosinalvital/paciente/{id}?tipo=&desde=&ate=`, `PUT|DELETE /registrosinalvital/paciente/{id}/ultimo` |
| Limiar de segurança | `POST /limiarseguranca`, `GET /limiarseguranca/paciente/{id}` |
| Alertas | `GET /alertas/paciente/{id}`, `PUT /alertas/{id}/resolver` |

O registro de um sinal vital (`POST /registrosinalvital`) aciona automaticamente
o motor de regras: se o valor estiver fora do limiar configurado para aquele
paciente e tipo de sinal, um `Alerta` é persistido e uma notificação push é
enviada ao cuidador vinculado (via o token FCM registrado em
`PUT /cuidador/token-fcm`).

## Autorização por recurso

Além do JWT (quem é você), cada endpoint que recebe um `pacienteId` checa
posse do recurso (`AutorizacaoService`): um paciente só acessa os próprios
dados; um cuidador só acessa os dados dos pacientes vinculados a ele. Chamadas
fora dessa regra retornam `403`. `GET /pacientes` lista apenas os pacientes do
cuidador autenticado, nunca todos do sistema.

## O que ainda falta (em relação à documentação do TCC)

- **RF04** (recuperação de senha por e-mail) - não implementado; depende de
  integração SMTP, deliberadamente deixado para depois dos requisitos
  essenciais.
- **RF11** (filtros avançados do dashboard) - o filtro por tipo e por período
  já funciona; combinações mais ricas (ex: tipo + período ao mesmo tempo)
  podem ser adicionadas conforme a necessidade do front-end.
- Testes automatizados (`src/test`) - ainda não existem.
- `GET /cuidador` e `GET /cuidador/{id}` ainda não têm restrição de posse
  (qualquer usuário autenticado pode ver nome/telefone de qualquer cuidador);
  deixado assim por ora porque não há um fluxo documentado que precise disso.
