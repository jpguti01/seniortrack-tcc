/// Espelha Paciente do backend (apenas os campos expostos pela API).
class Paciente {
  final int id;
  final String nome;
  final String email;
  final int idade;
  final String? telefone;

  Paciente({
    required this.id,
    required this.nome,
    required this.email,
    required this.idade,
    this.telefone,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      idade: json['idade'] as int,
      telefone: json['telefone'] as String?,
    );
  }
}
