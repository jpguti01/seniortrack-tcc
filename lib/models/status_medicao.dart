import 'limiar.dart';

/// Posição de uma medição em relação à faixa configurada pelo cuidador.
/// Mesma regra do backend (service.ClassificadorGravidade): dentro da faixa =
/// normal; fora = atenção; mais de 25% além do limite = crítico. Mantenha as
/// duas iguais. A faixa é definida por paciente e não é recomendação clínica.
enum StatusMedicao {
  normal('Dentro da faixa'),
  atencao('Fora da faixa'),
  critico('Muito fora da faixa');

  const StatusMedicao(this.rotulo);
  final String rotulo;

  static const margemCritica = 0.25;

  static StatusMedicao classificar(double valor, Limiar limiar) =>
      classificarFaixa(valor, limiar.valorMinimo, limiar.valorMaximo);

  static StatusMedicao classificarFaixa(
      double valor, double minimo, double maximo) {
    if (valor >= minimo && valor <= maximo) return normal;
    final critico = valor > maximo * (1 + margemCritica) ||
        valor < minimo * (1 - margemCritica);
    return critico ? StatusMedicao.critico : atencao;
  }
}
