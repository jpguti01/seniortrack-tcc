import 'dart:convert';
import 'dart:typed_data';

/// Espelha MedicamentoResponse do backend. Horários no formato "HH:mm".
class Medicamento {
  final int id;
  final String nome;
  final String? dosagem;
  final String? instrucoes;
  final List<String> horarios;

  /// Foto do comprimido ou da caixa como data URL (data:image/jpeg;base64,...).
  final String? foto;
  final bool ativo;

  Medicamento({
    required this.id,
    required this.nome,
    this.dosagem,
    this.instrucoes,
    required this.horarios,
    this.foto,
    this.ativo = true,
  });

  late final Uint8List? fotoBytes = bytesDaFoto(foto);

  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
        id: json['id'] as int,
        nome: json['nome'] as String,
        dosagem: json['dosagem'] as String?,
        instrucoes: json['instrucoes'] as String?,
        horarios: (json['horarios'] as List).cast<String>(),
        foto: json['foto'] as String?,
        ativo: json['ativo'] as bool? ?? true,
      );
}

/// Decodifica a data URL da foto; devolve null se ela estiver ausente ou inválida.
Uint8List? bytesDaFoto(String? dataUrl) {
  if (dataUrl == null || !dataUrl.startsWith('data:image/')) return null;
  final virgula = dataUrl.indexOf(',');
  if (virgula < 0) return null;
  try {
    return base64Decode(dataUrl.substring(virgula + 1));
  } on FormatException {
    return null;
  }
}

/// Espelha StatusDose do backend: ATRASADO = sem confirmação 30 minutos
/// depois do horário.
enum StatusDose {
  tomado('TOMADO', 'Tomado'),
  pendente('PENDENTE', 'No horário'),
  atrasado('ATRASADO', 'Atrasado');

  const StatusDose(this.valorApi, this.rotulo);
  final String valorApi;
  final String rotulo;

  static StatusDose fromApi(String valor) =>
      values.firstWhere((s) => s.valorApi == valor, orElse: () => pendente);
}

/// Uma dose prevista para hoje (DoseResponse do backend).
class Dose {
  final int medicamentoId;
  final String nome;
  final String? dosagem;
  final String? instrucoes;
  final String horario;
  final StatusDose status;
  final DateTime? confirmadaEm;

  Dose({
    required this.medicamentoId,
    required this.nome,
    this.dosagem,
    this.instrucoes,
    required this.horario,
    required this.status,
    this.confirmadaEm,
  });

  String get chave => '$medicamentoId@$horario';

  factory Dose.fromJson(Map<String, dynamic> json) => Dose(
        medicamentoId: json['medicamentoId'] as int,
        nome: json['nome'] as String,
        dosagem: json['dosagem'] as String?,
        instrucoes: json['instrucoes'] as String?,
        horario: json['horario'] as String,
        status: StatusDose.fromApi(json['status'] as String),
        confirmadaEm: json['confirmadaEm'] == null
            ? null
            : DateTime.parse(json['confirmadaEm'] as String),
      );
}

/// Adesão de um remédio no período (AdesaoResponse do backend): doses que já
/// deviam ter sido tomadas e quantas o paciente confirmou.
class Adesao {
  final int medicamentoId;
  final String nome;
  final String? dosagem;
  final bool ativo;
  final int previstas;
  final int tomadas;

  Adesao({
    required this.medicamentoId,
    required this.nome,
    this.dosagem,
    this.ativo = true,
    required this.previstas,
    required this.tomadas,
  });

  /// Entre 0 e 1; null quando nenhuma dose estava prevista no período.
  double? get percentual => previstas == 0 ? null : tomadas / previstas;

  factory Adesao.fromJson(Map<String, dynamic> json) => Adesao(
        medicamentoId: json['medicamentoId'] as int,
        nome: json['nome'] as String,
        dosagem: json['dosagem'] as String?,
        ativo: json['ativo'] as bool? ?? true,
        previstas: json['previstas'] as int,
        tomadas: json['tomadas'] as int,
      );

  /// Adesão somando todos os remédios (cada dose pesa igual).
  static double? geral(List<Adesao> itens) {
    final previstas = itens.fold<int>(0, (n, a) => n + a.previstas);
    if (previstas == 0) return null;
    return itens.fold<int>(0, (n, a) => n + a.tomadas) / previstas;
  }
}
