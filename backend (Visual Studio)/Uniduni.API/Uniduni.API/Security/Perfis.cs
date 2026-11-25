namespace Uniduni.API.Security;

public static class Perfis
{
    public const string Cliente = "Cliente";
    public const string Funcionario = "Funcionario";
    public const string Administrador = "Administrador";
    public const string Equipe = Funcionario + "," + Administrador;
}
