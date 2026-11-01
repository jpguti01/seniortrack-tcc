import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alerta.dart';
import '../models/sinal_vital.dart';
import '../models/solicitacao_vinculo.dart';
import '../models/tipo_sinal_vital.dart';
import '../providers/auth_provider.dart';
import '../services/alerta_service.dart';
import '../services/api_exception.dart';
import '../services/paciente_service.dart';
import '../services/sinal_vital_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alerta_card.dart';
import '../widgets/registrar_sinal_vital_dialog.dart';
import '../widgets/sinal_vital_card.dart';
import '../widgets/solicitacao_vinculo_card.dart';

class PacienteHomeScreen extends StatefulWidget {
  const PacienteHomeScreen({super.key});

  @override
  State<PacienteHomeScreen> createState() => _PacienteHomeScreenState();
}

class _PacienteHomeScreenState extends State<PacienteHomeScreen> {
  final _sinalVitalService = SinalVitalService();
  final _alertaService = AlertaService();
  final _pacienteService = PacienteService();

  late Future<List<SinalVital>> _historico;
  late Future<List<Alerta>> _alertas;
  late Future<List<SolicitacaoVinculo>> _solicitacoes;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final pacienteId = context.read<AuthProvider>().sessao!.id;
    setState(() {
      _historico = _sinalVitalService.listarPorPaciente(pacienteId);
      _alertas = _alertaService.listarPorPaciente(pacienteId);
      _solicitacoes = _pacienteService.listarSolicitacoesPendentes();
    });
  }

  Future<void> _responderSolicitacao(int id, {required bool aceitar}) async {
    try {
      if (aceitar) {
        await _pacienteService.aceitarSolicitacao(id);
      } else {
        await _pacienteService.recusarSolicitacao(id);
      }
      _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(aceitar ? 'Cuidador vinculado com sucesso.' : 'Solicitação recusada.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    }
  }

  Future<void> _registrar(TipoSinalVital tipo) async {
    final salvou = await abrirDialogoRegistrarSinalVital(context, tipo);
    if (salvou == true) {
      _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tipo.rotulo} registrado com sucesso.'),
            backgroundColor: AppTheme.sucesso,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.watch<AuthProvider>().sessao?.nome ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${nome.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<SolicitacaoVinculo>>(
              future: _solicitacoes,
              builder: (context, snapshot) {
                final pendentes = snapshot.data ?? [];
                if (pendentes.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solicitações de vínculo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...pendentes.map((s) => SolicitacaoVinculoCard(
                          solicitacao: s,
                          aoAceitar: () => _responderSolicitacao(s.id, aceitar: true),
                          aoRecusar: () => _responderSolicitacao(s.id, aceitar: false),
                        )),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            const Text('Registrar sinal vital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: TipoSinalVital.values.map((tipo) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => _registrar(tipo),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(84),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconePara(tipo), size: 28),
                          const SizedBox(height: 6),
                          Text(tipo.rotulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('Meus alertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Alerta>>(
              future: _alertas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _erroCarregamento();
                }
                final alertas = snapshot.data ?? [];
                final naoResolvidos = alertas.where((a) => !a.resolvido).toList();
                if (naoResolvidos.isEmpty) {
                  return const _MensagemVazia(texto: 'Nenhum alerta no momento. Tudo certo!');
                }
                return Column(children: naoResolvidos.map((a) => AlertaCard(alerta: a)).toList());
              },
            ),
            const SizedBox(height: 28),
            const Text('Histórico recente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<SinalVital>>(
              future: _historico,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _erroCarregamento();
                }
                final registros = snapshot.data ?? [];
                if (registros.isEmpty) {
                  return const _MensagemVazia(texto: 'Você ainda não registrou nenhum sinal vital.');
                }
                return Column(
                  children: registros.take(10).map((s) => SinalVitalCard(sinal: s)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroCarregamento() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Não foi possível carregar os dados.', style: TextStyle(color: Colors.red)),
          TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _MensagemVazia extends StatelessWidget {
  final String texto;
  const _MensagemVazia({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(texto, style: const TextStyle(color: Colors.black54)),
    );
  }
}
