r"""Validação da API no servidor de testes, isolado da conta de demonstração.

Inicie com: .\scripts\iniciar-local.ps1 -Banco telemonitoramento_teste
O script cria somente dados fictícios. Nunca usa a porta 8080.
"""
import argparse
import json
import secrets
from datetime import datetime, timedelta
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

BASE = 'http://localhost:8081'


def api(method, path, body=None, session=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if session:
        headers['Authorization'] = 'Bearer ' + session['token']
    request = Request(BASE + path, method=method, headers=headers,
                      data=None if body is None else json.dumps(body).encode())
    try:
        with urlopen(request, timeout=20) as response:
            status, raw = response.status, response.read()
    except HTTPError as error:
        status, raw = error.code, error.read()
    if status != expected:
        raise AssertionError(f'{method} {path}: esperado {expected}, recebido {status}')
    return json.loads(raw) if raw else None


def validar(contexto=None):
    sufixo = secrets.token_hex(5)
    senha = secrets.token_urlsafe(18)
    dados = dict(nome='Paciente de validação', idade=70,
                 email=f'validacao-paciente-{sufixo}@example.invalid',
                 senha=senha, telefone='+5511000000000')
    paciente = api('POST', '/auth/cadastro/paciente', dados, expected=201)
    paciente_id = paciente['id']
    convite = api('POST', '/convites', session=paciente)['codigo']
    cuidador_dados = dict(dados, nome='Cuidador de validação', idade=40,
                         email=f'validacao-cuidador-{sufixo}@example.invalid', codigoConvite=convite)
    cuidador = api('POST', '/auth/cadastro/cuidador', cuidador_dados, expected=201)
    vinculados = api('GET', '/pacientes', session=cuidador)
    assert [p['id'] for p in vinculados] == [paciente_id]
    print('OK: cadastro, convite e vínculo entre paciente e cuidador')

    # IDs do corpo não podem conceder acesso a outro paciente.
    api('GET', '/pacientes/1', session=cuidador, expected=403)
    api('POST', '/bemestar', {'humor': 'BEM'}, session=cuidador, expected=403)
    print('OK: acesso a outro paciente e escrita pelo perfil incorreto são negados')

    horario = (datetime.now() + timedelta(minutes=1)).strftime('%H:%M')
    remedio = api('POST', f'/medicamentos/paciente/{paciente_id}',
                 dict(nome='Remédio de teste', dosagem='Demonstração', horarios=[horario]),
                 session=cuidador, expected=201)
    doses = api('GET', f'/medicamentos/paciente/{paciente_id}/hoje', session=paciente)
    assert any(d['medicamentoId'] == remedio['id'] for d in doses)
    caminho = f'/medicamentos/{remedio["id"]}/tomadas'
    api('POST', caminho, {'horario': horario}, session=cuidador, expected=403)
    dose = api('POST', caminho, {'horario': horario}, session=paciente)
    assert dose['status'] == 'TOMADO'
    api('POST', caminho, {'horario': horario}, session=paciente)
    adesao = api('GET', f'/medicamentos/paciente/{paciente_id}/adesao', session=cuidador)
    assert len(adesao) == 1 and adesao[0]['tomadas'] == 1
    print('OK: rotina, confirmação Tomei, idempotência e adesão do cuidador')

    api('POST', '/bemestar', {'humor': 'BEM', 'observacao': 'Validação do diário.'}, session=paciente)
    api('POST', '/bemestar', {'humor': 'OTIMO', 'observacao': 'Resposta atualizada.'}, session=paciente)
    checkins = api('GET', f'/bemestar/paciente/{paciente_id}', session=cuidador)
    assert len(checkins) == 1 and checkins[0]['humor'] == 'OTIMO'
    print('OK: check-in atualiza o mesmo dia e fica disponível ao cuidador')

    chamado = api('POST', '/sos', session=paciente, expected=201)
    painel = api('GET', '/cuidador/painel', session=cuidador)
    assert any(p['pacienteId'] == paciente_id for p in painel)
    api('PUT', f'/sos/{chamado["id"]}/atender', session=paciente, expected=403)
    atendido = api('PUT', f'/sos/{chamado["id"]}/atender', session=cuidador)
    assert atendido['atendidoEm'] is not None
    print('OK: SOS aparece no cuidador e somente ele confirma o atendimento')

    api('POST', '/registrosinalvital', {'tipoSinalVital': 'PESO', 'valorSinalVital': 70},
        session=paciente, expected=201)
    historico = api('GET', f'/registrosinalvital/paciente/{paciente_id}', session=cuidador)
    assert len(historico) == 1 and historico[0]['valorSinalVital'] == 70
    print('OK: registro e histórico para o relatório clínico')

    if contexto:
        Path(contexto).write_text(json.dumps(dict(
            base=BASE, paciente=paciente, cuidador=cuidador,
            pacienteEmail=dados['email'], cuidadorEmail=cuidador_dados['email'], senha=senha,
            medicamentoId=remedio['id'], horario=horario)), encoding='utf-8')
    print('Validação concluída no banco de testes; nenhuma conta original foi alterada.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contexto', help='Arquivo local temporário para a validação do navegador; contém credenciais fictícias.')
    validar(parser.parse_args().contexto)
