import 'package:flutter_test/flutter_test.dart';
import 'package:telemonitoramento_app/models/sessao_usuario.dart';
import 'package:telemonitoramento_app/providers/auth_provider.dart';
import 'package:telemonitoramento_app/services/api_client.dart';
import 'package:telemonitoramento_app/services/api_exception.dart';
import 'package:telemonitoramento_app/services/auth_service.dart';
import 'package:telemonitoramento_app/services/biometria_service.dart';

class AuthFake extends AuthService {
  SessaoUsuario? salva;
  Object? erroValidacao;
  TipoUsuario? perfilRecebido;
  int validacoes = 0;
  final exemplo = SessaoUsuario(
      token: 'token', tipo: TipoUsuario.paciente, id: 1, nome: 'Maria');
  @override
  Future<SessaoUsuario?> restaurarSessao() async => salva;
  @override
  Future<void> validarSessao() async {
    validacoes++;
    if (erroValidacao != null) throw erroValidacao!;
  }

  @override
  Future<SessaoUsuario> login(String email, String senha,
      {TipoUsuario? perfil}) async {
    perfilRecebido = perfil;
    return salva = exemplo;
  }

  @override
  Future<void> logout() async {
    salva = null;
  }

  @override
  Future<Map<String, bool>> opcoes() async => {'codigo': true, 'google': false};
}

class BiometriaFake extends BiometriaService {
  bool ativa = false;
  bool aprovada = true;
  @override
  Future<bool> disponivel() async => true;
  @override
  Future<bool> habilitada() async => ativa;
  @override
  Future<void> configurar(bool valor) async {
    ativa = valor;
  }

  @override
  Future<bool> autenticar() async => aprovada;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthFake service;
  late BiometriaFake biometria;
  late AuthProvider auth;

  Future<void> iniciar({bool bloqueada = false}) async {
    service = AuthFake();
    biometria = BiometriaFake()..ativa = bloqueada;
    if (bloqueada) service.salva = service.exemplo;
    auth = AuthProvider(authService: service, biometria: biometria);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() {
    auth.dispose();
    ApiClient.instancia.sessaoBloqueada = false;
  });

  test('Sessão protegida permanece bloqueada ao reabrir o aplicativo',
      () async {
    await iniciar(bloqueada: true);
    expect(auth.status, StatusAuth.bloqueado);
    expect(auth.sessao, isNull);
    expect(ApiClient.instancia.sessaoBloqueada, isTrue);
  });

  test('Cancelar biometria não libera a sessão nem consulta a API', () async {
    await iniciar(bloqueada: true);
    biometria.aprovada = false;
    expect(await auth.desbloquearSessao(), isFalse);
    expect(auth.status, StatusAuth.bloqueado);
    expect(service.validacoes, 0);
  });

  test('Biometria válida só libera depois de validar o token no servidor',
      () async {
    await iniciar(bloqueada: true);
    expect(await auth.desbloquearSessao(), isTrue);
    expect(service.validacoes, 1);
    expect(auth.status, StatusAuth.autenticado);
    expect(auth.sessao?.nome, 'Maria');
  });

  test('Falha de conexão mantém a proteção biométrica', () async {
    await iniciar(bloqueada: true);
    service.erroValidacao = StateError('Sem conexão');
    await expectLater(auth.desbloquearSessao(), throwsStateError);
    expect(auth.status, StatusAuth.bloqueado);
    expect(auth.sessao, isNull);
    expect(ApiClient.instancia.sessaoBloqueada, isTrue);
  });

  test('Token expirado remove a sessão e exige novo login', () async {
    await iniciar(bloqueada: true);
    service.erroValidacao = ApiException(401, 'Sessão expirada');
    await expectLater(auth.desbloquearSessao(), throwsA(isA<ApiException>()));
    expect(auth.status, StatusAuth.naoAutenticado);
    expect(auth.sessao, isNull);
    expect(biometria.ativa, isFalse);
    expect(service.salva, isNull);
  });

  test('Ativar biometria protege a sessão seguinte e preserva o perfil enviado',
      () async {
    await iniciar();
    await auth.login('maria@example.com', 'senha123',
        usarBiometria: true, perfil: TipoUsuario.paciente);
    expect(service.perfilRecebido, TipoUsuario.paciente);
    expect(biometria.ativa, isTrue);
    auth.bloquearSessao();
    expect(auth.status, StatusAuth.bloqueado);
    expect(auth.sessao, isNull);
  });

  test('Sair remove a sessão e desativa a biometria', () async {
    await iniciar(bloqueada: true);
    await auth.logout();
    expect(await auth.desbloquearSessao(), isFalse);
    expect(biometria.ativa, isFalse);
    expect(auth.status, StatusAuth.naoAutenticado);
  });
}
