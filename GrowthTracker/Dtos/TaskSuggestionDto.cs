namespace GrowthTracker.API.Dtos;

public class TaskSuggestionDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
}
