using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
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
        private readonly IFirebaseService _firebaseService;

        public DailyTasksController(AppDbContext context, ILogger<DailyTasksController> logger, IFirebaseService firebaseService)
        {
            _context = context;
            _logger = logger;
            _firebaseService = firebaseService;
        }

        /// <summary>
        /// Kullanıcının bugün için üretilmiş görev önerilerini getirir.
        /// </summary>
        [HttpGet("today")]
        public async Task<IActionResult> GetTodaysTasks([FromQuery] Guid userId)
        {
            var today = DateTime.UtcNow.Date;
            var tasks = await _context.DailyTasks
                .Where(t => t.UserId == userId && t.CreatedAt.Date == today)
                .OrderBy(t => t.CreatedAt)
                .AsNoTracking()
                .ToListAsync();

            return Ok(tasks);
        }

        /// <summary>
        /// Kullanıcı bir görevi seçer (active görev olarak işaretler).
        /// </summary>
        [HttpPost("{id:int}/select")]
        public async Task<IActionResult> SelectTask(int id, [FromQuery] Guid userId)
        {
            var task = await _context.DailyTasks.FindAsync(id);
            if (task == null)
                return NotFound();

            if (task.UserId != userId)
                return Forbid();

            // Bugün tamamlanan görev sayısı >= 3 ise yeni seçime izin verme
            var today = DateTime.UtcNow.Date;
            var completedToday = await _context.DailyTasks
                .CountAsync(t => t.UserId == userId && t.IsCompleted && t.CompletedAt.HasValue && t.CompletedAt.Value.Date == today);

            if (completedToday >= 3)
                return BadRequest(new { message = "Günlük hedefe ulaştın! Bugün en fazla 3 görev tamamlayabilirsin.", completedToday });

            // Aynı görev zaten aktif seçiliyse idempotent dön
            var alreadyActive = await _context.TaskSelections
                .AnyAsync(ts => ts.DailyTaskId == id && ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);
            if (alreadyActive)
                return Ok(new { message = "Task already selected.", taskId = id });

            // Daha önce bu kullanıcı için aktif seçim varsa Skipped yap
            var existingSelection = await _context.TaskSelections
                .FirstOrDefaultAsync(ts => ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);
            if (existingSelection != null)
                existingSelection.Status = TaskSelectionStatus.Skipped;

            task.IsSelected = true;

            var selection = new TaskSelection
            {
                UserId = userId,
                DailyTaskId = id,
                SelectedAt = DateTime.UtcNow,
                Status = TaskSelectionStatus.Active
            };

            await _context.TaskSelections.AddAsync(selection);

            // Görev için hatırlatma: estimatedMinutes sonra bildirim gönder
            var reminderTime = DateTime.UtcNow.AddMinutes(task.EstimatedMinutes > 0 ? task.EstimatedMinutes : 30);
            var reminder = new Reminder
            {
                UserId = userId,
                DailyTaskId = id,
                Title = task.Title,
                Description = $"Görevi tamamlamayı unutma! ⏱ Tahmini süre: {task.EstimatedMinutes} dk",
                ReminderDate = reminderTime,
                IsCompleted = false
            };
            await _context.Reminders.AddAsync(reminder);

            await _context.SaveChangesAsync();

            // Seçim onayı push bildirimi (anlık)
            var deviceTokens = await _context.DeviceTokens
                .Where(dt => dt.UserId == userId)
                .Select(dt => dt.Token)
                .ToListAsync();

            foreach (var token in deviceTokens)
            {
                try
                {
                    await _firebaseService.SendNotificationAsync(
                        token,
                        $"✅ Görev Seçildi: {task.Title}",
                        $"Harika! {task.EstimatedMinutes} dakikada tamamlayabilirsin. 💪 Başarılar!");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Push notification gönderilemedi, UserId: {UserId}", userId);
                }
            }

            return Ok(new { message = "Task selected.", taskId = id, selectionId = selection.Id, reminderAt = reminderTime });
        }

        /// <summary>
        /// Görev tamamlandı olarak işaretlenir.
        /// </summary>
        [HttpPost("{id:int}/complete")]
        public async Task<IActionResult> CompleteTask(int id, [FromQuery] Guid userId)
        {
            var task = await _context.DailyTasks.FindAsync(id);
            if (task == null)
                return NotFound();

            if (task.UserId != userId)
                return Forbid();

            task.IsCompleted = true;
            task.CompletedAt = DateTime.UtcNow;

            var selection = await _context.TaskSelections
                .FirstOrDefaultAsync(ts => ts.DailyTaskId == id && ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);

            if (selection != null)
            {
                selection.Status = TaskSelectionStatus.Completed;
                selection.CompletedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Task completed.", taskId = id, completedAt = task.CompletedAt });
        }

        /// <summary>
        /// Kullanıcının geçmiş tamamlanan görevleri.
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> GetHistory([FromQuery] Guid userId, [FromQuery] int days = 30)
        {
            var since = DateTime.UtcNow.Date.AddDays(-days);
            var tasks = await _context.DailyTasks
                .Where(t => t.UserId == userId && t.IsCompleted && t.CompletedAt >= since)
                .OrderByDescending(t => t.CompletedAt)
                .AsNoTracking()
                .ToListAsync();

            return Ok(tasks);
        }

        /// <summary>
        /// Kategoriye göre tamamlanan görev istatistikleri.
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats([FromQuery] Guid userId)
        {
            var stats = await _context.DailyTasks
                .Where(t => t.UserId == userId && t.IsCompleted)
                .GroupBy(t => t.Category)
                .Select(g => new
                {
                    Category = g.Key,
                    CompletedCount = g.Count(),
                    TotalMinutes = g.Sum(t => t.EstimatedMinutes)
                })
                .ToListAsync();

            var totalCompleted = await _context.DailyTasks
                .CountAsync(t => t.UserId == userId && t.IsCompleted);

            return Ok(new { totalCompleted, byCategory = stats });
        }

        /// <summary>
        /// Tüm görevler (admin/debug).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllTasks()
        {
            var tasks = await _context.DailyTasks.AsNoTracking().ToListAsync();
            return Ok(tasks);
        }

        /// <summary>
        /// AI öneri kartını DailyTask olarak kaydeder ve seçili olarak işaretler.
        /// </summary>
        [HttpPost("from-suggestion")]
        public async Task<IActionResult> CreateAndSelectFromSuggestion([FromQuery] Guid userId, [FromBody] GrowthTracker.API.Dtos.TaskSuggestionDto suggestion)
        {
            // Bugün tamamlanan görev sayısı >= 3 ise yeni seçime izin verme
            var today = DateTime.UtcNow.Date;
            var completedToday = await _context.DailyTasks
                .CountAsync(t => t.UserId == userId && t.IsCompleted && t.CompletedAt.HasValue && t.CompletedAt.Value.Date == today);

            if (completedToday >= 3)
                return BadRequest(new { message = "Günlük hedefe ulaştın! Bugün en fazla 3 görev tamamlayabilirsin.", completedToday });

            // Daha önce aktif seçim varsa Skipped yap
            var existingSelection = await _context.TaskSelections
                .FirstOrDefaultAsync(ts => ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);
            if (existingSelection != null)
                existingSelection.Status = TaskSelectionStatus.Skipped;

            var task = new DailyTask
            {
                UserId = userId,
                Title = suggestion.Title,
                Description = suggestion.Description,
                Category = suggestion.Category,
                EstimatedMinutes = suggestion.EstimatedMinutes,
                IsSelected = true,
                CreatedAt = DateTime.UtcNow
            };
            await _context.DailyTasks.AddAsync(task);
            await _context.SaveChangesAsync();

            var selection = new TaskSelection
            {
                UserId = userId,
                DailyTaskId = task.Id,
                SelectedAt = DateTime.UtcNow,
                Status = TaskSelectionStatus.Active
            };
            await _context.TaskSelections.AddAsync(selection);

            var reminderTime = DateTime.UtcNow.AddMinutes(task.EstimatedMinutes > 0 ? task.EstimatedMinutes : 30);
            var reminder = new Reminder
            {
                UserId = userId,
                DailyTaskId = task.Id,
                Title = task.Title,
                Description = $"Görevi tamamlamayı unutma! ⏱ Tahmini süre: {task.EstimatedMinutes} dk",
                ReminderDate = reminderTime,
                IsCompleted = false
            };
            await _context.Reminders.AddAsync(reminder);
            await _context.SaveChangesAsync();

            var deviceTokens = await _context.DeviceTokens
                .Where(dt => dt.UserId == userId)
                .Select(dt => dt.Token)
                .ToListAsync();

            foreach (var token in deviceTokens)
            {
                try
                {
                    await _firebaseService.SendNotificationAsync(
                        token,
                        $"✅ Görev Seçildi: {task.Title}",
                        $"Harika! {task.EstimatedMinutes} dakikada tamamlayabilirsin. 💪 Başarılar!");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Push notification gönderilemedi, UserId: {UserId}", userId);
                }
            }

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
