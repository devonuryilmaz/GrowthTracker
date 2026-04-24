using System;
using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Services;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.BackgroundServices;

public class AIGeneratorJob
{
    private readonly ILogger<AIGeneratorJob> _logger;
    private readonly OpenAIService _openAIService;
    private readonly AppDbContext _dbContext;

    public AIGeneratorJob(ILogger<AIGeneratorJob> logger, OpenAIService openAIService, AppDbContext dbContext)
    {
        _logger = logger;
        _openAIService = openAIService;
        _dbContext = dbContext;
    }

    public async Task GenerateTasksAsync()
    {
        _logger.LogInformation("AI Task Generation started at: {Time}", DateTimeOffset.Now);

        var users = await _dbContext.Users.AsNoTracking().ToListAsync();

        if (users.Count == 0)
        {
            _logger.LogWarning("No users found. Skipping AI task generation.");
            return;
        }

        var today = DateTime.UtcNow.Date;
        var taskList = new List<DailyTask>();

        foreach (var user in users)
        {
            // İdempotent kontrol: bugün zaten görev üretilmişse atla
            var alreadyGenerated = await _dbContext.DailyTasks
                .AnyAsync(t => t.UserId == user.Id && t.CreatedAt.Date == today);

            if (alreadyGenerated)
            {
                _logger.LogInformation("Tasks already generated for User {UserId} today. Skipping.", user.Id);
                continue;
            }

            _logger.LogInformation("Generating tasks for User: {UserId}", user.Id);

            var suggestions = await _openAIService.GenerateTaskSuggestionsAsync(user);

            if (suggestions.Count == 0)
            {
                _logger.LogWarning("No suggestions returned for User {UserId}.", user.Id);
                continue;
            }

            foreach (var suggestion in suggestions)
            {
                taskList.Add(new DailyTask
                {
                    UserId = user.Id,
                    Title = suggestion.Title,
                    Description = suggestion.Description,
                    Category = suggestion.Category,
                    EstimatedMinutes = suggestion.EstimatedMinutes,
                    CreatedAt = DateTime.UtcNow
                });
            }

            _logger.LogInformation("Generated {Count} tasks for User {UserId}.", suggestions.Count, user.Id);
        }

        if (taskList.Count > 0)
        {
            await _dbContext.DailyTasks.AddRangeAsync(taskList);
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Saved {Count} tasks to database.", taskList.Count);
        }
    }
}
