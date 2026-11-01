import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/paciente.dart';
import '../providers/auth_provider.dart';
import '../services/paciente_service.dart';
import '../widgets/vincular_paciente_dialog.dart';
import 'paciente_detalhe_screen.dart';

class CuidadorHomeScreen extends StatefulWidget {
  const CuidadorHomeScreen({super.key});

  @override
  State<CuidadorHomeScreen> createState() => _CuidadorHomeScreenState();
}

class _CuidadorHomeScreenState extends State<CuidadorHomeScreen> {
  final _pacienteService = PacienteService();
  late Future<List<Paciente>> _pacientes;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _pacientes = _pacienteService.listarMeusPacientes();
    });
  }

  Future<void> _vincularPaciente() async {
    final enviou = await abrirDialogoVincularPaciente(context);
    if (enviou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada. O paciente precisa aceitar no app dele.')),
      );
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
        child: FutureBuilder<List<Paciente>>(
          future: _pacientes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  const Center(child: Text('Não foi possível carregar seus pacientes.')),
                  Center(child: TextButton(onPressed: _carregar, child: const Text('Tentar novamente'))),
                ],
              );
            }
            final pacientes = snapshot.data ?? [];
            if (pacientes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.people_outline, size: 48, color: Colors.black38),
                  SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Nenhum paciente vinculado à sua conta ainda. Toque em "Solicitar vínculo" e peça para o paciente aceitar no app dele.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: pacientes.length,
              itemBuilder: (context, index) {
                final paciente = pacientes[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.elderly)),
                    title: Text(paciente.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${paciente.idade} anos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PacienteDetalheScreen(paciente: paciente)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vincularPaciente,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Solicitar vínculo'),
      ),
    );
  }
}
