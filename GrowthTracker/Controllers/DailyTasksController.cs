using GrowthTracker.API.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GrowtTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DailyTasksController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<DailyTasksController> _logger;

        public DailyTasksController(AppDbContext context, ILogger<DailyTasksController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllTasks()
        {
            var tasks = await _context.DailyTasks.AsNoTracking().ToListAsync();
            _logger.LogInformation("Retrieved all daily tasks");
            return Ok(tasks);
        }

        [HttpGet("today")]
        public async Task<IActionResult> GetTodaysTasks()
        {
            var today = DateTime.UtcNow.Date;
            var tasks = await _context.DailyTasks
                .Where(t => t.CreatedAt.Date == today)
                .OrderByDescending(t => t.CreatedAt)
                .Take(10)
                .AsNoTracking()
                .ToListAsync();

            _logger.LogInformation("Retrieved today's daily tasks");
            return Ok(tasks);
        }
    }
}
