import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telemonitoramento_app/models/alerta.dart';
import 'package:telemonitoramento_app/models/bem_estar.dart';
import 'package:telemonitoramento_app/models/chamado_sos.dart';
import 'package:telemonitoramento_app/models/limiar.dart';
import 'package:telemonitoramento_app/models/medicamento.dart';
import 'package:telemonitoramento_app/models/paciente.dart';
import 'package:telemonitoramento_app/models/resumo_paciente.dart';
import 'package:telemonitoramento_app/models/sinal_vital.dart';
import 'package:telemonitoramento_app/models/status_medicao.dart';
import 'package:telemonitoramento_app/models/tipo_sinal_vital.dart';
import 'package:telemonitoramento_app/services/alerta_service.dart';
import 'package:telemonitoramento_app/services/painel_cuidador_service.dart';
import 'package:telemonitoramento_app/services/paciente_service.dart';
import 'package:telemonitoramento_app/services/relatorio_paciente_service.dart';
import 'package:telemonitoramento_app/services/resumo_cuidador_service.dart';
import 'package:telemonitoramento_app/services/sinal_vital_service.dart';
import 'package:telemonitoramento_app/utils/leitura_bluetooth.dart';
import 'package:telemonitoramento_app/utils/numero_falado.dart';
import 'package:telemonitoramento_app/utils/telefone.dart';
import 'package:telemonitoramento_app/widgets/barra_medicao_simples.dart';
import 'package:telemonitoramento_app/widgets/botao_sos.dart';
import 'package:telemonitoramento_app/widgets/checkin_bem_estar_card.dart';
import 'package:telemonitoramento_app/widgets/remedios_do_dia_card.dart';

final agora = DateTime(2026, 11, 2, 15);
final paciente =
    Paciente(id: 1, nome: 'Maria Souza', email: 'maria@example.com', idade: 78);
Limiar limiar(TipoSinalVital tipo, double min, double max) =>
    Limiar(id: 1, tipo: tipo, valorMinimo: min, valorMaximo: max);
Alerta alerta(int id,
        {GravidadeAlerta gravidade = GravidadeAlerta.atencao,
        DateTime? data}) =>
    Alerta(
        id: id,
        mensagem: 'Fora da faixa',
        dataHora: data ?? agora,
        resolvido: false,
        tipoSinal: TipoSinalVital.glicemia,
        valorSinal: 250,
        gravidade: gravidade);
ByteData bytes(List<int> valores) =>
    ByteData.sublistView(Uint8List.fromList(valores));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Entrada por voz', () {
    test('Entende números ditos por extenso e em algarismos', () {
      expect(extrairNumeroFalado('cento e trinta'), 130);
      expect(extrairNumeroFalado('130'), 130);
      expect(extrairNumeroFalado('72,5'), 72.5);
      expect(extrairNumeroFalado('duzentos e cinquenta'), 250);
      expect(extrairNumeroFalado('setenta e dois vírgula cinco'), 72.5);
      expect(extrairNumeroFalado('noventa e oito ponto cinco'), 98.5);
      expect(extrairNumeroFalado('setenta e dois e meio'), 72.5);
    });

    test('Usa o primeiro número da frase e ignora o resto', () {
      expect(
          extrairNumeroFalado('minha pressão está cento e vinte por oitenta'),
          120);
      expect(extrairNumeroFalado('120 por 80'), 120);
      expect(extrairNumeroFalado('não sei'), isNull);
      expect(extrairNumeroFalado(''), isNull);
    });
  });

  group('WhatsApp', () {
    test('Completa o código do Brasil e recusa números incompletos', () {
      expect(telefoneInternacional('(11) 98765-4321'), '5511987654321');
      expect(telefoneInternacional('+55 11 98765-4321'), '5511987654321');
      expect(telefoneInternacional('011 98765-4321'), '5511987654321');
      expect(telefoneInternacional('1234'), isNull);
      expect(linkWhatsApp('(11) 98765-4321', mensagem: 'Olá').toString(),
          'https://wa.me/5511987654321?text=Ol%C3%A1');
    });
  });

  group('Bluetooth (perfis padrão)', () {
    test('Pressão sistólica em mmHg e convertida de kPa', () {
      expect(
          lerPressaoSistolica(
              bytes([0x00, 0x78, 0x00, 0x50, 0x00, 0x5D, 0x00])),
          120);
      expect(
          lerPressaoSistolica(
              bytes([0x01, 0xA0, 0xF0, 0x6B, 0xF0, 0x7C, 0xF0])),
          120);
      expect(
          lerPressaoSistolica(
              bytes([0x00, 0xFF, 0x07, 0x50, 0x00, 0x5D, 0x00])),
          isNull);
    });

    test('Glicemia em kg/L e em mol/L vira mg/dL', () {
      final base = [0x01, 0x00, 0xEA, 0x07, 11, 2, 8, 30, 0];
      expect(lerGlicemia(bytes([0x02, ...base, 0x6E, 0xB0, 0x11])), 110);
      expect(lerGlicemia(bytes([0x06, ...base, 0x3D, 0xC0, 0x11])), 110);
      expect(lerGlicemia(bytes([0x00, ...base])), isNull);
    });

    test('Peso em kg e em libras', () {
      expect(lerPeso(bytes([0x00, 0xA4, 0x38])), 72.5);
      expect(lerPeso(bytes([0x01, 0x80, 0x3E])), 72.6);
      expect(lerPeso(bytes([0x00, 0xFF, 0xFF])), isNull);
    });
  });

  group('Gravidade', () {
    test('Mesma regra do backend (exemplos do ClassificadorGravidade)', () {
      expect(
          StatusMedicao.classificarFaixa(100, 70, 140), StatusMedicao.normal);
      expect(
          StatusMedicao.classificarFaixa(165, 70, 140), StatusMedicao.atencao);
      expect(
          StatusMedicao.classificarFaixa(250, 70, 140), StatusMedicao.critico);
      expect(
          StatusMedicao.classificarFaixa(155, 90, 130), StatusMedicao.atencao);
      expect(
          StatusMedicao.classificarFaixa(180, 90, 130), StatusMedicao.critico);
      expect(
          StatusMedicao.classificarFaixa(50, 70, 140), StatusMedicao.critico);
    });

    test('Alerta lê gravidade e persistência; antigos viram atenção', () {
      Map<String, dynamic> json(Object? gravidade, Object? persistente) => {
            'id': 1,
            'mensagem': 'x',
            'dataHora': '2026-11-02T10:00:00',
            'resolvido': false,
            'gravidade': gravidade,
            'persistente': persistente,
            'registroSinalVital': {
              'tipoSinalVital': 'GLICEMIA',
              'valorSinalVital': 250
            },
          };
      final critico = Alerta.fromJson(json('CRITICO', true));
      expect(critico.gravidade, GravidadeAlerta.critico);
      expect(critico.persistente, isTrue);
      final antigo = Alerta.fromJson(json(null, null));
      expect(antigo.gravidade, GravidadeAlerta.atencao);
      expect(antigo.persistente, isFalse);
    });

    test('Cuidador vê SOS e críticos antes dos demais', () {
      final comCritico =
          ResumoPaciente(paciente: paciente, historico: [], alertas: [
        alerta(1, data: agora),
        alerta(2,
            gravidade: GravidadeAlerta.critico,
            data: agora.subtract(const Duration(hours: 3))),
      ]);
      expect(comCritico.pendentes.first.id, 2);
      expect(comCritico.temCritico, isTrue);
      final comSos = ResumoPaciente(
          paciente: paciente,
          historico: [],
          alertas: [],
          cuidados: PainelPaciente(pacienteId: 1, sosPendentes: [
            ChamadoSos(
                id: 9,
                pacienteId: 1,
                pacienteNome: 'Maria',
                criadoEm: agora,
                atendido: false)
          ]));
      expect(comSos.pediuAjuda, isTrue);
      expect(comSos.prioridade, greaterThan(comCritico.prioridade));
    });
  });

  group('Remédios e bem-estar', () {
    test('Dose, adesão e check-in leem o formato da API', () {
      final dose = Dose.fromJson({
        'medicamentoId': 3,
        'nome': 'Losartana',
        'dosagem': '50 mg',
        'instrucoes': null,
        'data': '2026-11-02',
        'horario': '08:00',
        'status': 'ATRASADO',
        'confirmadaEm': null,
      });
      expect(dose.status, StatusDose.atrasado);
      expect(dose.chave, '3@08:00');
      final adesao = [
        Adesao(medicamentoId: 1, nome: 'A', previstas: 10, tomadas: 9),
        Adesao(medicamentoId: 2, nome: 'B', previstas: 10, tomadas: 5),
        Adesao(medicamentoId: 3, nome: 'C', previstas: 0, tomadas: 0),
      ];
      expect(Adesao.geral(adesao), .7);
      expect(adesao.last.percentual, isNull);
      final checkin = CheckinBemEstar.fromJson({
        'id': 1,
        'data': '2026-11-02',
        'humor': 'COM_DOR',
        'observacao': 'Dor nas costas',
        'registradoEm': '2026-11-02T09:00:00',
      });
      expect(checkin.humor.preocupante, isTrue);
      expect(checkin.eDoDia(agora), isTrue);
    });

    test('Foto inválida não quebra o card', () {
      expect(bytesDaFoto('data:image/png;base64,iVBORw0KGgo='), isNotNull);
      expect(bytesDaFoto('data:image/png;base64,@@@'), isNull);
      expect(bytesDaFoto('https://exemplo.com/foto.png'), isNull);
    });
  });

  group('Relatório clínico', () {
    test('Estatística usa só o tipo pedido e conta o que saiu da faixa', () {
      final registros = [
        for (final v in [100.0, 165.0, 250.0])
          SinalVital(
              id: v.toInt(),
              tipo: TipoSinalVital.glicemia,
              valor: v,
              horaRegistro: agora),
        SinalVital(
            id: 1, tipo: TipoSinalVital.peso, valor: 70, horaRegistro: agora),
      ];
      final e = EstatisticaSinal.calcular(TipoSinalVital.glicemia, registros,
          limiar(TipoSinalVital.glicemia, 70, 140));
      expect(e.medicoes, 3);
      expect(e.minimo, 100);
      expect(e.maximo, 250);
      expect(e.media, closeTo(171.67, .01));
      expect(e.foraDaFaixa, 2);
      expect(
          EstatisticaSinal.calcular(TipoSinalVital.peso, registros, null)
              .foraDaFaixa,
          isNull);
    });

    test('Gera um PDF válido mesmo com seções indisponíveis', () async {
      final pdf = await RelatorioPacienteService().gerarClinico(
        paciente: paciente,
        dias: 30,
        emitidoEm: agora,
        registros: [
          SinalVital(
              id: 1,
              tipo: TipoSinalVital.glicemia,
              valor: 250,
              horaRegistro: agora)
        ],
        limiares: [limiar(TipoSinalVital.glicemia, 70, 140)],
        alertas: [alerta(1, gravidade: GravidadeAlerta.critico)],
        adesao: [
          Adesao(medicamentoId: 1, nome: 'Losartana', previstas: 4, tomadas: 3)
        ],
        checkins: null,
        chamados: const [],
      );
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    });
  });

  group('Painel do cuidador', () {
    test('Pendências do dia entram no resumo de cada paciente', () async {
      final service = ResumoCuidadorService(
          pacientes: _Pacientes(),
          sinais: _Sinais(),
          alertas: _Alertas(),
          painel: _Painel());
      final resumo = (await service.carregar()).single;
      expect(resumo.cuidados!.dosesAtrasadasHoje, 1);
      expect(resumo.pediuAjuda, isTrue);
    });

    test('Falha no painel do dia não esconde as medições', () async {
      final service = ResumoCuidadorService(
          pacientes: _Pacientes(),
          sinais: _Sinais(),
          alertas: _Alertas(),
          painel: _Painel(falhar: true));
      final resumo = (await service.carregar()).single;
      expect(resumo.cuidados, isNull);
      expect(resumo.historico, isEmpty);
    });
  });

  group('Telas do paciente', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<void> mostrar(WidgetTester tester, Widget widget) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: widget))));
    }

    testWidgets('SOS só avisa depois da confirmação', (tester) async {
      var acionado = 0;
      await mostrar(
          tester, BotaoSos(grande: true, onConfirmar: () async => acionado++));
      await tester.tap(find.text('Pedir ajuda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(acionado, 0);
      await tester.tap(find.text('Pedir ajuda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, pedir ajuda'));
      await tester.pumpAndSettle();
      expect(acionado, 1);
    });

    // Leitores de tela (TalkBack, VoiceOver) e o app web com acessibilidade
    // ativa acionam o botão pela árvore de semântica, não pelo toque na tela.
    testWidgets('SOS e check-in podem ser acionados por leitor de tela',
        (tester) async {
      final semantica = tester.ensureSemantics();
      Humor? escolhido;
      await mostrar(
          tester,
          Column(children: [
            BotaoSos(onConfirmar: () async {}),
            CheckinBemEstarCard(
                hoje: null, onResponder: (humor) => escolhido = humor),
          ]));
      expect(
          tester.getSemantics(find.bySemanticsLabel('Pedir ajuda ao cuidador')),
          isSemantics(isButton: true, hasTapAction: true));
      expect(tester.getSemantics(find.bySemanticsLabel('Estou com dor')),
          isSemantics(isButton: true, hasTapAction: true));
      tester.semantics.tap(find.semantics.byLabel('Estou com dor'));
      expect(escolhido, Humor.comDor);
      semantica.dispose();
    });

    testWidgets('"Tomei" aparece só nas doses não confirmadas', (tester) async {
      Dose? tomada;
      await mostrar(
          tester,
          RemediosDoDiaCard(
            grande: true,
            doses: [
              Dose(
                  medicamentoId: 1,
                  nome: 'Losartana',
                  horario: '08:00',
                  status: StatusDose.tomado,
                  confirmadaEm: DateTime(2026, 11, 2, 8, 5)),
              Dose(
                  medicamentoId: 2,
                  nome: 'Metformina',
                  horario: '12:00',
                  status: StatusDose.atrasado),
            ],
            onTomei: (dose) => tomada = dose,
          ));
      expect(find.text('1 de 2 tomados'), findsOneWidget);
      expect(find.text('Tomei'), findsOneWidget);
      expect(find.text('Atrasado'), findsOneWidget);
      await tester.tap(find.text('Tomei'));
      expect(tomada!.nome, 'Metformina');
    });

    testWidgets('Check-in envia o humor escolhido e mostra a resposta do dia',
        (tester) async {
      Humor? escolhido;
      await mostrar(
          tester,
          CheckinBemEstarCard(
            grande: true,
            hoje: CheckinBemEstar(
                id: 1, data: agora, humor: Humor.bem, registradoEm: agora),
            onResponder: (humor) => escolhido = humor,
          ));
      expect(find.textContaining('Hoje você respondeu "Bem"'), findsOneWidget);
      await tester.tap(find.text('Com dor'));
      expect(escolhido, Humor.comDor);
    });

    testWidgets('Barra simples explica a medição sem gráfico', (tester) async {
      await mostrar(
          tester,
          BarraMedicaoSimples(
            tipo: TipoSinalVital.glicemia,
            ultimo: SinalVital(
                id: 1,
                tipo: TipoSinalVital.glicemia,
                valor: 250,
                horaRegistro: agora),
            limiar: limiar(TipoSinalVital.glicemia, 70, 140),
          ));
      expect(
          find.text('Bem acima da faixa: avise seu cuidador'), findsOneWidget);
      expect(find.text('Faixa combinada: 70 a 140 mg/dL'), findsOneWidget);
    });
  });
}

class _Pacientes extends PacienteService {
  @override
  Future<List<Paciente>> listarMeusPacientes() async => [paciente];
}

class _Sinais extends SinalVitalService {
  @override
  Future<List<SinalVital>> listarPorPaciente(int pacienteId,
          {TipoSinalVital? tipo}) async =>
      [];
}

class _Alertas extends AlertaService {
  @override
  Future<List<Alerta>> listarPorPaciente(int pacienteId) async => [];
}

class _Painel extends PainelCuidadorService {
  final bool falhar;
  _Painel({this.falhar = false});

  @override
  Future<List<PainelPaciente>> carregar() async {
    if (falhar) throw StateError('painel indisponível');
    return [
      PainelPaciente(
          pacienteId: 1,
          dosesAtrasadasHoje: 1,
          dosesPrevistasHoje: 3,
          sosPendentes: [
            ChamadoSos(
                id: 1,
                pacienteId: 1,
                pacienteNome: 'Maria Souza',
                criadoEm: agora,
                atendido: false)
          ])
    ];
  }
}
