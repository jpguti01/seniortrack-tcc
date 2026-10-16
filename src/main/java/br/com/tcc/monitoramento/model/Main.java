/*package br.com.tcc.monitoramento.model;

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
public class Main {
    public static void main(String[] args) {


        Paciente daniel = new Paciente("Daniel", 22, "11975246260");
        RegistroSinalVital r1 = new RegistroSinalVital(RegistroSinalVital.TipoSinalVital.PESO, 30.0);
        RegistroSinalVital r2 = new RegistroSinalVital(RegistroSinalVital.TipoSinalVital.GLICEMIA, 100.0);

        daniel.adicionarRegistro(r1);
        daniel.adicionarRegistro(r2);






        Cuidador gabriela = new Cuidador("Gabriela", 21, "11992401607", daniel);

        LimiarSeguranca limiarDaniel = new LimiarSeguranca(100.0, 40.0, RegistroSinalVital.TipoSinalVital.PESO);

       gabriela.definirLimiarPaciente(daniel, limiarDaniel );

       gabriela.checarRegistroPaciente(daniel);

        System.out.println(r1.getHoraRegistro());






    }
}
 */