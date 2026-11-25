using Microsoft.EntityFrameworkCore;
using Uniduni.API.Models;

namespace Uniduni.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<Produto> Produtos { get; set; }
        public DbSet<Sessao> Sessoes { get; set; }
        public DbSet<Categoria> Categorias { get; set; }
        public DbSet<ProdutoVariacao> ProdutoVariacoes { get; set; }
        public DbSet<MovimentacaoEstoque> MovimentacoesEstoque { get; set; }
        public DbSet<CarrinhoItemLoja> CarrinhoItensLoja { get; set; }
        public DbSet<PedidoLoja> PedidosLoja { get; set; }
        public DbSet<ItemPedidoLoja> ItensPedidoLoja { get; set; }
        public DbSet<PagamentoSimulado> PagamentosSimulados { get; set; }
        public DbSet<EventoPedidoLoja> EventosPedidoLoja { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CarrinhoItemLoja>().HasKey(x=>new{x.UsuarioId,x.VariacaoId});
            modelBuilder.Entity<CarrinhoItemLoja>().HasOne(x=>x.Variacao).WithMany().HasForeignKey(x=>x.VariacaoId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<PedidoLoja>().HasIndex(x=>new{x.UsuarioId,x.OperacaoId}).IsUnique();
            modelBuilder.Entity<PedidoLoja>().Property(x=>x.Total).HasPrecision(12,2);
            modelBuilder.Entity<PedidoLoja>().HasOne(x=>x.Usuario).WithMany().HasForeignKey(x=>x.UsuarioId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<PedidoLoja>().HasMany(x=>x.Itens).WithOne().HasForeignKey(x=>x.PedidoId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<PedidoLoja>().HasMany(x=>x.Pagamentos).WithOne().HasForeignKey(x=>x.PedidoId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<PedidoLoja>().HasMany(x=>x.Eventos).WithOne().HasForeignKey(x=>x.PedidoId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<ItemPedidoLoja>().Property(x=>x.PrecoUnitario).HasPrecision(10,2);
            modelBuilder.Entity<PagamentoSimulado>().Property(x=>x.Valor).HasPrecision(12,2);
            modelBuilder.Entity<Produto>().Property(p => p.Preco).HasPrecision(10, 2);
            modelBuilder.Entity<Sessao>().Property(s => s.TokenHash).HasColumnType("char(64)");
            modelBuilder.Entity<Sessao>().HasIndex(s => s.TokenHash).IsUnique();
            modelBuilder.Entity<ProdutoVariacao>().ToTable("ProdutoVariacoes", t => t.UseSqlOutputClause(false));
            modelBuilder.Entity<ProdutoVariacao>().Property(v => v.Versao).IsRowVersion();
            modelBuilder.Entity<ProdutoVariacao>().HasIndex(v => new { v.ProdutoId, v.Cor, v.Tamanho }).IsUnique();
            modelBuilder.Entity<MovimentacaoEstoque>().HasOne(m => m.Variacao).WithMany().HasForeignKey(m => m.VariacaoId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<MovimentacaoEstoque>().HasIndex(m => m.OperacaoId).IsUnique();
        }
    }
}
