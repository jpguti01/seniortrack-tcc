/// Espelha Paciente do backend (apenas os campos expostos pela API).
class Paciente {
  final int id;
  final String nome;
  final String email;
  final int idade;
  final String? telefone;
  final ContatoCuidador? cuidador;

  Paciente({
    required this.id,
    required this.nome,
    required this.email,
    required this.idade,
    this.telefone,
    this.cuidador,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      idade: json['idade'] as int,
      telefone: json['telefone'] as String?,
      cuidador: json['cuidador'] is Map<String, dynamic>
          ? ContatoCuidador.fromJson(json['cuidador'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ContatoCuidador {
  final String nome;
  final String? telefone;
  const ContatoCuidador({required this.nome, this.telefone});
  factory ContatoCuidador.fromJson(Map<String, dynamic> json) =>
      ContatoCuidador(
        nome: json['nome'] as String,
        telefone: json['telefone'] as String?,
      );
}
