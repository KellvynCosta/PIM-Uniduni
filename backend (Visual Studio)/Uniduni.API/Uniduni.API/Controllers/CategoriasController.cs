using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Data;

namespace Uniduni.API.Controllers;
[ApiController,Route("api/[controller]")]
public class CategoriasController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get() => Ok(await db.Categorias.AsNoTracking().OrderBy(c=>c.Id)
        .Select(c=>new { c.Id,c.Nome,c.Descricao }).ToListAsync());
}
