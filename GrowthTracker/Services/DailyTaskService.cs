using GrowthTracker.API.Data;
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.Services;

public class DailyTaskService : IDailyTaskService
{
    private readonly AppDbContext _context;
    private readonly IFirebaseService _firebaseService;
    private readonly ILogger<DailyTaskService> _logger;

    public DailyTaskService(AppDbContext context, IFirebaseService firebaseService, ILogger<DailyTaskService> logger)
    {
        _context = context;
        _firebaseService = firebaseService;
        _logger = logger;
    }

    public async Task<List<DailyTask>> GetTodaysTasksAsync(Guid userId)
    {
        var today = DateTime.UtcNow.Date;
        return await _context.DailyTasks
            .Where(t => t.UserId == userId && t.CreatedAt.Date == today)
            .OrderBy(t => t.CreatedAt)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<ServiceResult<TaskSelectionResultDto>> SelectTaskAsync(int taskId, Guid userId)
    {
        var task = await _context.DailyTasks.FindAsync(taskId);
        if (task == null)
            return ServiceResult<TaskSelectionResultDto>.Failure("Task not found.", 404);

        if (task.UserId != userId)
            return ServiceResult<TaskSelectionResultDto>.Failure("Forbidden.", 403);

        var today = DateTime.UtcNow.Date;
        var completedToday = await _context.DailyTasks
            .CountAsync(t => t.UserId == userId && t.IsCompleted && t.CompletedAt.HasValue && t.CompletedAt.Value.Date == today);

        if (completedToday >= 3)
            return ServiceResult<TaskSelectionResultDto>.Failure(
                $"Günlük hedefe ulaştın! Bugün en fazla 3 görev tamamlayabilirsin. completedToday:{completedToday}", 400);

        var alreadyActive = await _context.TaskSelections
            .AnyAsync(ts => ts.DailyTaskId == taskId && ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);
        if (alreadyActive)
            return ServiceResult<TaskSelectionResultDto>.Success(new TaskSelectionResultDto { TaskId = taskId });

        var (selection, reminderAt) = await ActivateTaskAsync(task, userId);

        await SendSelectionNotificationAsync(userId, task);

        return ServiceResult<TaskSelectionResultDto>.Success(new TaskSelectionResultDto
        {
            TaskId = taskId,
            SelectionId = selection.Id,
            ReminderAt = reminderAt
        });
    }

    public async Task<ServiceResult<TaskCompletionResultDto>> CompleteTaskAsync(int taskId, Guid userId)
    {
        var task = await _context.DailyTasks.FindAsync(taskId);
        if (task == null)
            return ServiceResult<TaskCompletionResultDto>.Failure("Task not found.", 404);

        if (task.UserId != userId)
            return ServiceResult<TaskCompletionResultDto>.Failure("Forbidden.", 403);

        task.IsCompleted = true;
        task.CompletedAt = DateTime.UtcNow;

        var selection = await _context.TaskSelections
            .FirstOrDefaultAsync(ts => ts.DailyTaskId == taskId && ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);

        if (selection != null)
        {
            selection.Status = TaskSelectionStatus.Completed;
            selection.CompletedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return ServiceResult<TaskCompletionResultDto>.Success(new TaskCompletionResultDto
        {
            TaskId = taskId,
            CompletedAt = task.CompletedAt
        });
    }

    public async Task<List<DailyTask>> GetHistoryAsync(Guid userId, int days)
    {
        var since = DateTime.UtcNow.Date.AddDays(-days);
        return await _context.DailyTasks
            .Where(t => t.UserId == userId && t.IsCompleted && t.CompletedAt >= since)
            .OrderByDescending(t => t.CompletedAt)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<DailyTaskStatsDto> GetStatsAsync(Guid userId)
    {
        var byCategory = await _context.DailyTasks
            .Where(t => t.UserId == userId && t.IsCompleted)
            .GroupBy(t => t.Category)
            .Select(g => new CategoryStatDto
            {
                Category = g.Key,
                CompletedCount = g.Count(),
                TotalMinutes = g.Sum(t => t.EstimatedMinutes)
            })
            .ToListAsync();

        var totalCompleted = await _context.DailyTasks
            .CountAsync(t => t.UserId == userId && t.IsCompleted);

        return new DailyTaskStatsDto { TotalCompleted = totalCompleted, ByCategory = byCategory };
    }

    public async Task<List<DailyTask>> GetAllTasksAsync()
    {
        return await _context.DailyTasks.AsNoTracking().ToListAsync();
    }

    public async Task<ServiceResult<DailyTask>> CreateAndSelectFromSuggestionAsync(Guid userId, TaskSuggestionDto suggestion)
    {
        var today = DateTime.UtcNow.Date;
        var completedToday = await _context.DailyTasks
            .CountAsync(t => t.UserId == userId && t.IsCompleted && t.CompletedAt.HasValue && t.CompletedAt.Value.Date == today);

        if (completedToday >= 3)
            return ServiceResult<DailyTask>.Failure(
                $"Günlük hedefe ulaştın! Bugün en fazla 3 görev tamamlayabilirsin. completedToday:{completedToday}", 400);

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

        await ActivateTaskAsync(task, userId);

        await SendSelectionNotificationAsync(userId, task);

        return ServiceResult<DailyTask>.Success(task, 200);
    }

    public async Task<DailyTask?> GetTaskByIdAsync(int taskId, Guid userId)
    {
        return await _context.DailyTasks
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == taskId && t.UserId == userId);
    }

    // --- Private helpers ---

    private async Task<(TaskSelection selection, DateTime reminderAt)> ActivateTaskAsync(DailyTask task, Guid userId)
    {
        var existingSelection = await _context.TaskSelections
            .FirstOrDefaultAsync(ts => ts.UserId == userId && ts.Status == TaskSelectionStatus.Active);
        if (existingSelection != null)
            existingSelection.Status = TaskSelectionStatus.Skipped;

        task.IsSelected = true;

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

        return (selection, reminderTime);
    }

    private async Task SendSelectionNotificationAsync(Guid userId, DailyTask task)
    {
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
    }
}
