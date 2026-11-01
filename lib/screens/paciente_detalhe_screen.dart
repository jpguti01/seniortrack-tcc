import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/limiar.dart';
import '../models/paciente.dart';
import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';
import '../services/alerta_service.dart';
import '../services/api_exception.dart';
import '../services/limiar_service.dart';
import '../services/sinal_vital_service.dart';
import '../widgets/alerta_card.dart';
import '../widgets/sinal_vital_card.dart';

class PacienteDetalheScreen extends StatefulWidget {
  final Paciente paciente;
  const PacienteDetalheScreen({super.key, required this.paciente});

  @override
  State<PacienteDetalheScreen> createState() => _PacienteDetalheScreenState();
}

class _PacienteDetalheScreenState extends State<PacienteDetalheScreen> {
  final _sinalVitalService = SinalVitalService();
  final _alertaService = AlertaService();
  final _limiarService = LimiarService();

  late Future<List<SinalVital>> _historico;
  late Future<List<Alerta>> _alertas;
  late Future<List<Limiar>> _limiares;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _historico = _sinalVitalService.listarPorPaciente(widget.paciente.id);
      _alertas = _alertaService.listarPorPaciente(widget.paciente.id);
      _limiares = _limiarService.listarPorPaciente(widget.paciente.id);
    });
  }

  Future<void> _resolverAlerta(int alertaId) async {
    try {
      await _alertaService.resolver(alertaId);
      _carregar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    }
  }

  Future<void> _abrirFormularioLimiar() async {
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormularioLimiar(pacienteId: widget.paciente.id),
    );
    if (salvou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.paciente.nome),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Histórico'),
              Tab(text: 'Alertas'),
              Tab(text: 'Limiares'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: FutureBuilder<List<SinalVital>>(
                future: _historico,
                builder: (context, snapshot) => _listaOuVazio(
                  snapshot: snapshot,
                  vazio: 'Nenhum sinal vital registrado ainda.',
                  builder: (dados) => dados.map((s) => SinalVitalCard(sinal: s)).toList(),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: FutureBuilder<List<Alerta>>(
                future: _alertas,
                builder: (context, snapshot) => _listaOuVazio(
                  snapshot: snapshot,
                  vazio: 'Nenhum alerta para este paciente.',
                  builder: (dados) => dados
                      .map((a) => AlertaCard(
                            alerta: a,
                            aoResolver: a.resolvido ? null : () => _resolverAlerta(a.id),
                          ))
                      .toList(),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: FutureBuilder<List<Limiar>>(
                future: _limiares,
                builder: (context, snapshot) => _listaOuVazio(
                  snapshot: snapshot,
                  vazio: 'Nenhum limiar configurado ainda.',
                  builder: (dados) => dados.map((l) => _LimiarCard(limiar: l)).toList(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirFormularioLimiar,
          icon: const Icon(Icons.add),
          label: const Text('Novo limiar'),
        ),
      ),
    );
  }

  Widget _listaOuVazio<T>({
    required AsyncSnapshot<List<T>> snapshot,
    required String vazio,
    required List<Widget> Function(List<T>) builder,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ListView(
        children: const [
          SizedBox(height: 60),
          Center(child: Text('Não foi possível carregar.', style: TextStyle(color: Colors.red))),
        ],
      );
    }
    final dados = snapshot.data ?? [];
    if (dados.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Center(child: Text(vazio, style: const TextStyle(color: Colors.black54))),
        ],
      );
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: builder(dados));
  }
}

class _LimiarCard extends StatelessWidget {
  final Limiar limiar;
  const _LimiarCard({required this.limiar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(iconePara(limiar.tipo), color: Colors.blue.shade700)),
        title: Text(limiar.tipo.rotulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Faixa normal: ${limiar.valorMinimo.toStringAsFixed(1)} a ${limiar.valorMaximo.toStringAsFixed(1)} ${limiar.tipo.unidade}',
        ),
      ),
    );
  }
}

class _FormularioLimiar extends StatefulWidget {
  final int pacienteId;
  const _FormularioLimiar({required this.pacienteId});

  @override
  State<_FormularioLimiar> createState() => _FormularioLimiarState();
}

class _FormularioLimiarState extends State<_FormularioLimiar> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _service = LimiarService();
  TipoSinalVital _tipo = TipoSinalVital.pressaoArterial;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _service.salvar(
        pacienteId: widget.pacienteId,
        tipo: _tipo,
        valorMinimo: double.parse(_minController.text.replaceAll(',', '.')),
        valorMaximo: double.parse(_maxController.text.replaceAll(',', '.')),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível salvar. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Novo limiar de segurança', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<TipoSinalVital>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de sinal vital'),
              items: TipoSinalVital.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.rotulo)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Mínimo (${_tipo.unidade})'),
                    validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Inválido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Máximo (${_tipo.unidade})'),
                    validator: (v) {
                      final max = double.tryParse((v ?? '').replaceAll(',', '.'));
                      final min = double.tryParse(_minController.text.replaceAll(',', '.'));
                      if (max == null) return 'Inválido';
                      if (min != null && max <= min) return 'Deve ser > mínimo';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : _salvar,
              child: _enviando
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar limiar'),
            ),
          ],
        ),
      ),
    );
  }
}
