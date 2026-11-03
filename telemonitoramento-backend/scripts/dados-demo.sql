\set ON_ERROR_STOP on
BEGIN;
SET LOCAL TIME ZONE 'America/Sao_Paulo';
SELECT pg_advisory_xact_lock(hashtext('seniortrack-demo-v1'));

-- Somente contas explicitamente identificadas como Demo podem ser preparadas.
CREATE TEMP TABLE demo_contexto ON COMMIT DROP AS
SELECT p.id AS paciente_id, c.id AS cuidador_id, localtimestamp AS agora
FROM tb_paciente p CROSS JOIN tb_cuidador c
WHERE lower(p.email) = lower(:'paciente_email')
  AND lower(c.email) = lower(:'cuidador_email')
  AND p.nome ILIKE '%demo%' AND c.nome ILIKE '%demo%';

DO $$ BEGIN
  IF (SELECT count(*) FROM demo_contexto) <> 1 THEN
    RAISE EXCEPTION 'Informe um paciente Demo e um cuidador Demo existentes e únicos.';
  END IF;
  IF EXISTS (SELECT 1 FROM tb_paciente p JOIN demo_contexto d ON p.id=d.paciente_id
             WHERE p.cuidador_id IS NOT NULL AND p.cuidador_id<>d.cuidador_id) THEN
    RAISE EXCEPTION 'O paciente está vinculado a outro cuidador. Nenhum vínculo será substituído.';
  END IF;
END $$;

CREATE TEMP TABLE demo_autenticacao ON COMMIT DROP AS
SELECT 'PACIENTE' AS tipo,p.id,p.email,p.senha_hash FROM tb_paciente p JOIN demo_contexto d ON d.paciente_id=p.id
UNION ALL
SELECT 'CUIDADOR',c.id,c.email,c.senha_hash FROM tb_cuidador c JOIN demo_contexto d ON d.cuidador_id=c.id;

-- Perfis de apoio usam domínio reservado e senha bloqueada: não criam novos acessos.
CREATE TEMP TABLE demo_perfis(codigo text, nome text, email text, idade integer) ON COMMIT DROP;
INSERT INTO demo_perfis VALUES
 ('maria','Maria Helena (Paciente Demo)','maria.helena@demo.seniortrack.invalid',68),
 ('antonio','Antônio Silva (Paciente Demo)','antonio.silva@demo.seniortrack.invalid',80),
 ('carlos','Carlos Almeida (Paciente Demo)','carlos.almeida@demo.seniortrack.invalid',75),
 ('lucia','Lúcia Santos (Primeiro Acesso Demo)','lucia.santos@demo.seniortrack.invalid',70);

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM tb_paciente p JOIN demo_perfis f ON lower(f.email)=lower(p.email)
             CROSS JOIN demo_contexto d
             WHERE p.senha_hash<>'!SENIORTRACK_DEMO_LOGIN_DESATIVADO!'
                OR p.cuidador_id IS DISTINCT FROM d.cuidador_id) THEN
    RAISE EXCEPTION 'Há um perfil reservado de demonstração com dados incompatíveis. Operação cancelada.';
  END IF;
END $$;

INSERT INTO tb_paciente(nome,email,idade,telefone,data_nascimento,criado_em,senha_hash,cuidador_id)
SELECT f.nome,f.email,f.idade,'(11) 00000-0000',
       (current_date-make_interval(years=>f.idade))::date,
       d.agora-interval '45 days','!SENIORTRACK_DEMO_LOGIN_DESATIVADO!',d.cuidador_id
FROM demo_perfis f CROSS JOIN demo_contexto d
WHERE NOT EXISTS (SELECT 1 FROM tb_paciente p WHERE lower(p.email)=lower(f.email));

-- Telefones inequivocamente fictícios; e-mails, nomes e senhas originais são mantidos.
UPDATE tb_paciente p SET telefone='(11) 00000-0000',
  data_nascimento=coalesce(p.data_nascimento,(current_date-make_interval(years=>p.idade))::date),
  cuidador_id=d.cuidador_id
FROM demo_contexto d WHERE p.id=d.paciente_id;
UPDATE tb_cuidador c SET telefone='(11) 00000-0000'
FROM demo_contexto d WHERE c.id=d.cuidador_id;

CREATE TEMP TABLE demo_escopo(paciente_id bigint PRIMARY KEY,codigo text) ON COMMIT DROP;
INSERT INTO demo_escopo SELECT paciente_id,'principal' FROM demo_contexto;
INSERT INTO demo_escopo SELECT p.id,f.codigo FROM tb_paciente p JOIN demo_perfis f ON p.email=f.email;

-- Limiares exclusivamente ilustrativos. Não substituem um plano de cuidados.
INSERT INTO tb_limiar_seguranca(paciente_id,cuidador_id,tipo_sinal_vital,valor_min,valor_max)
SELECT e.paciente_id,d.cuidador_id,t.tipo,t.minimo,t.maximo
FROM demo_escopo e CROSS JOIN demo_contexto d
CROSS JOIN LATERAL (VALUES
 ('PRESSAO_ARTERIAL',CASE WHEN e.codigo='principal' THEN 80.0 ELSE 95.0 END,
   CASE WHEN e.codigo='principal' THEN 130.0 WHEN e.codigo='maria' THEN 140.0 ELSE 145.0 END),
 ('GLICEMIA',70.0,CASE WHEN e.codigo='principal' THEN 140.0 WHEN e.codigo='antonio' THEN 150.0 ELSE 145.0 END),
 ('PESO',CASE WHEN e.codigo IN ('maria','lucia') THEN 55.0 ELSE 65.0 END,
   CASE WHEN e.codigo='maria' THEN 75.0 WHEN e.codigo='antonio' THEN 90.0 ELSE 85.0 END)
) AS t(tipo,minimo,maximo)
WHERE NOT EXISTS (SELECT 1 FROM tb_limiar_seguranca l
                  WHERE l.paciente_id=e.paciente_id AND l.tipo_sinal_vital=t.tipo);

-- Horários fixos tornam a carga repetível sem duplicar registros.
CREATE TEMP TABLE demo_medicoes ON COMMIT DROP AS
SELECT e.paciente_id,e.codigo,a.tipo,(cal.dia::date+a.hora) AS hora_registro,
       extract(doy FROM cal.dia)::integer AS fase,a.turno
FROM demo_escopo e CROSS JOIN demo_contexto d
CROSS JOIN generate_series(current_date-29,current_date,interval '1 day') cal(dia)
CROSS JOIN (VALUES ('PRESSAO_ARTERIAL',time '08:00',0),('GLICEMIA',time '08:10',0),
                   ('PESO',time '08:20',0),('PRESSAO_ARTERIAL',time '18:00',1),
                   ('GLICEMIA',time '18:10',1)) a(tipo,hora,turno)
WHERE e.codigo<>'lucia' AND cal.dia::date+a.hora<=d.agora
  AND (e.codigo<>'carlos' OR cal.dia::date<=current_date-3);

ALTER TABLE demo_medicoes ADD COLUMN valor double precision;
UPDATE demo_medicoes SET valor=CASE tipo
 WHEN 'PRESSAO_ARTERIAL' THEN CASE codigo
   WHEN 'principal' THEN CASE WHEN fase%10=0 THEN 147+turno*2 ELSE 112+(fase+turno*3)%12 END
   WHEN 'maria' THEN 118+(fase+turno*2)%14
   WHEN 'antonio' THEN CASE WHEN hora_registro::date=current_date THEN 151+turno*4
                           WHEN fase%12=0 THEN 153 ELSE 128+(fase+turno)%10 END
   ELSE 122+(fase+turno)%15 END
 WHEN 'GLICEMIA' THEN CASE codigo
   WHEN 'principal' THEN CASE WHEN hora_registro::date=current_date THEN 165+turno*3
                             WHEN fase%11=0 THEN 175 ELSE 95+(fase+turno*4)%22 END
   WHEN 'maria' THEN 92+(fase+turno*5)%20
   WHEN 'antonio' THEN CASE WHEN hora_registro::date=current_date THEN 185+turno*3
                           WHEN fase%9=0 THEN 178 ELSE 105+(fase+turno*3)%30 END
   ELSE 97+(fase+turno)%20 END
 ELSE round((CASE codigo WHEN 'principal' THEN 72.2 WHEN 'maria' THEN 63.4
               WHEN 'antonio' THEN 76.8 ELSE 70.2 END+(fase%9-4)*0.1)::numeric,1)::double precision END;

INSERT INTO tb_registro_sinal_vital(paciente_id,tipo_sinal,valor_sinal,hora_registro)
SELECT m.paciente_id,m.tipo,m.valor,m.hora_registro FROM demo_medicoes m
WHERE NOT EXISTS (SELECT 1 FROM tb_registro_sinal_vital r
                  WHERE r.paciente_id=m.paciente_id AND r.tipo_sinal=m.tipo AND r.hora_registro=m.hora_registro)
ORDER BY m.hora_registro,m.paciente_id,m.tipo;

-- Criação direta das ocorrências de apresentação: não envia notificações externas.
INSERT INTO tb_alerta(registro_sinal_vital_id,data_hora,mensagem,resolvido)
SELECT r.id,r.hora_registro+interval '1 second',
       format('%s fora da faixa configurada: valor medido %s (faixa normal: %s a %s)',
              r.tipo_sinal,r.valor_sinal,l.valor_min,l.valor_max),r.hora_registro::date<current_date
FROM tb_registro_sinal_vital r
JOIN demo_medicoes m ON m.paciente_id=r.paciente_id AND m.tipo=r.tipo_sinal AND m.hora_registro=r.hora_registro
CROSS JOIN LATERAL (SELECT lim.* FROM tb_limiar_seguranca lim
  WHERE lim.paciente_id=r.paciente_id AND lim.tipo_sinal_vital=r.tipo_sinal ORDER BY lim.id DESC LIMIT 1) l
WHERE (r.valor_sinal<l.valor_min OR r.valor_sinal>l.valor_max)
  AND NOT EXISTS (SELECT 1 FROM tb_alerta a WHERE a.registro_sinal_vital_id=r.id);

INSERT INTO tb_solicitacao_vinculo(cuidador_id,paciente_id,status,criado_em)
SELECT d.cuidador_id,e.paciente_id,'ACEITA',greatest(p.criado_em,c.criado_em)+interval '1 second'
FROM demo_escopo e CROSS JOIN demo_contexto d
JOIN tb_cuidador c ON c.id=d.cuidador_id JOIN tb_paciente p ON p.id=e.paciente_id
WHERE NOT EXISTS (SELECT 1 FROM tb_solicitacao_vinculo s
                  WHERE s.cuidador_id=d.cuidador_id AND s.paciente_id=e.paciente_id AND s.status='ACEITA');

-- Repetição segura do aceite/recusa entre as mesmas duas contas de demonstração.
-- Uma nova execução não recria um pedido que já tenha sido respondido.
INSERT INTO tb_solicitacao_vinculo(cuidador_id,paciente_id,status,criado_em)
SELECT d.cuidador_id,d.paciente_id,'PENDENTE',greatest(p.criado_em,c.criado_em)+interval '2 seconds'
FROM demo_contexto d JOIN tb_paciente p ON p.id=d.paciente_id JOIN tb_cuidador c ON c.id=d.cuidador_id
WHERE NOT EXISTS (SELECT 1 FROM tb_solicitacao_vinculo s
                  WHERE s.cuidador_id=d.cuidador_id AND s.paciente_id=d.paciente_id
                    AND (s.status='PENDENTE' OR s.criado_em=greatest(p.criado_em,c.criado_em)+interval '2 seconds'));

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM demo_autenticacao a
    LEFT JOIN tb_paciente p ON a.tipo='PACIENTE' AND p.id=a.id
    LEFT JOIN tb_cuidador c ON a.tipo='CUIDADOR' AND c.id=a.id
    WHERE a.email IS DISTINCT FROM coalesce(p.email,c.email)
       OR a.senha_hash IS DISTINCT FROM coalesce(p.senha_hash,c.senha_hash)) THEN
    RAISE EXCEPTION 'A integridade das credenciais foi alterada. Operação cancelada.';
  END IF;
END $$;

SELECT p.nome,
 (SELECT count(*) FROM tb_registro_sinal_vital r WHERE r.paciente_id=p.id) AS registros,
 (SELECT count(*) FROM tb_limiar_seguranca l WHERE l.paciente_id=p.id) AS limiares,
 (SELECT count(*) FROM tb_alerta a JOIN tb_registro_sinal_vital r ON r.id=a.registro_sinal_vital_id
   WHERE r.paciente_id=p.id AND NOT a.resolvido) AS alertas_pendentes,
 (SELECT max(hora_registro) FROM tb_registro_sinal_vital r WHERE r.paciente_id=p.id) AS ultima_medicao
FROM demo_escopo e JOIN tb_paciente p ON p.id=e.paciente_id ORDER BY p.id;

\if :aplicar
COMMIT;
\else
ROLLBACK;
\endif
