namespace GrowthTracker.API.Dtos;

public class DailyTaskStatsDto
{
    public int TotalCompleted { get; set; }
    public List<CategoryStatDto> ByCategory { get; set; } = new();
}

public class CategoryStatDto
{
    public string Category { get; set; } = string.Empty;
    public int CompletedCount { get; set; }
    public int TotalMinutes { get; set; }
}
