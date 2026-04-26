using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Interfaces;

public interface IDailyTaskService
{
    Task<List<DailyTask>> GetTodaysTasksAsync(Guid userId);
    Task<ServiceResult<TaskSelectionResultDto>> SelectTaskAsync(int taskId, Guid userId);
    Task<ServiceResult<TaskCompletionResultDto>> CompleteTaskAsync(int taskId, Guid userId);
    Task<List<DailyTask>> GetHistoryAsync(Guid userId, int days);
    Task<DailyTaskStatsDto> GetStatsAsync(Guid userId);
    Task<List<DailyTask>> GetAllTasksAsync();
    Task<ServiceResult<DailyTask>> CreateAndSelectFromSuggestionAsync(Guid userId, TaskSuggestionDto suggestion);
    Task<DailyTask?> GetTaskByIdAsync(int taskId, Guid userId);
}
