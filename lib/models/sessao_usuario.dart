enum TipoUsuario { paciente, cuidador }

/// Espelha o TokenResponse devolvido por /auth/login e /auth/cadastro/*.
class SessaoUsuario {
  final String token;
  final TipoUsuario tipo;
  final int id;
  final String nome;

  SessaoUsuario({
    required this.token,
    required this.tipo,
    required this.id,
    required this.nome,
  });

  factory SessaoUsuario.fromJson(Map<String, dynamic> json) {
    return SessaoUsuario(
      token: json['token'] as String,
      tipo: (json['tipo'] as String) == 'CUIDADOR' ? TipoUsuario.cuidador : TipoUsuario.paciente,
      id: json['id'] as int,
      nome: json['nome'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'tipo': tipo == TipoUsuario.cuidador ? 'CUIDADOR' : 'PACIENTE',
        'id': id,
        'nome': nome,
      };
}
