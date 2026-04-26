using GrowthTracker.API.Dtos;
using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GrowtTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DailyTasksController : ControllerBase
    {
        private readonly IDailyTaskService _dailyTaskService;
        private readonly ILogger<DailyTasksController> _logger;

        public DailyTasksController(IDailyTaskService dailyTaskService, ILogger<DailyTasksController> logger)
        {
            _dailyTaskService = dailyTaskService;
            _logger = logger;
        }

        /// <summary>
        /// Kullanıcının bugün için üretilmiş görev önerilerini getirir.
        /// </summary>
        [HttpGet("today")]
        public async Task<IActionResult> GetTodaysTasks([FromQuery] Guid userId)
        {
            var tasks = await _dailyTaskService.GetTodaysTasksAsync(userId);
            return Ok(tasks);
        }

        /// <summary>
        /// Kullanıcı bir görevi seçer (active görev olarak işaretler).
        /// </summary>
        [HttpPost("{id:int}/select")]
        public async Task<IActionResult> SelectTask(int id, [FromQuery] Guid userId)
        {
            var result = await _dailyTaskService.SelectTaskAsync(id, userId);

            if (!result.IsSuccess)
            {
                if (result.StatusCode == 404) return NotFound();
                if (result.StatusCode == 403) return Forbid();
                return BadRequest(new { message = result.Error });
            }

            var data = result.Data!;
            if (data.SelectionId == 0)
                return Ok(new { message = "Task already selected.", taskId = data.TaskId });

            return Ok(new { message = "Task selected.", taskId = data.TaskId, selectionId = data.SelectionId, reminderAt = data.ReminderAt });
        }

        /// <summary>
        /// Görev tamamlandı olarak işaretlenir.
        /// </summary>
        [HttpPost("{id:int}/complete")]
        public async Task<IActionResult> CompleteTask(int id, [FromQuery] Guid userId)
        {
            var result = await _dailyTaskService.CompleteTaskAsync(id, userId);

            if (!result.IsSuccess)
            {
                if (result.StatusCode == 404) return NotFound();
                if (result.StatusCode == 403) return Forbid();
                return BadRequest(new { message = result.Error });
            }

            var data = result.Data!;
            return Ok(new { message = "Task completed.", taskId = data.TaskId, completedAt = data.CompletedAt });
        }

        /// <summary>
        /// Kullanıcının geçmiş tamamlanan görevleri.
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> GetHistory([FromQuery] Guid userId, [FromQuery] int days = 30)
        {
            var tasks = await _dailyTaskService.GetHistoryAsync(userId, days);
            return Ok(tasks);
        }

        /// <summary>
        /// Kategoriye göre tamamlanan görev istatistikleri.
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats([FromQuery] Guid userId)
        {
            var stats = await _dailyTaskService.GetStatsAsync(userId);
            return Ok(new { totalCompleted = stats.TotalCompleted, byCategory = stats.ByCategory });
        }

        /// <summary>
        /// Tüm görevler (admin/debug).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllTasks()
        {
            var tasks = await _dailyTaskService.GetAllTasksAsync();
            return Ok(tasks);
        }

        /// <summary>
        /// AI öneri kartını DailyTask olarak kaydeder ve seçili olarak işaretler.
        /// </summary>
        [HttpPost("from-suggestion")]
        public async Task<IActionResult> CreateAndSelectFromSuggestion([FromQuery] Guid userId, [FromBody] TaskSuggestionDto suggestion)
        {
            var result = await _dailyTaskService.CreateAndSelectFromSuggestionAsync(userId, suggestion);

            if (!result.IsSuccess)
                return BadRequest(new { message = result.Error });

            var task = result.Data!;
            return Ok(new
            {
                task.Id,
                task.Title,
                task.Description,
                task.Category,
                task.EstimatedMinutes,
                task.IsSelected,
                task.IsCompleted,
                task.CreatedAt,
                task.CompletedAt,
                task.UserId,
            });
        }
    }
}
