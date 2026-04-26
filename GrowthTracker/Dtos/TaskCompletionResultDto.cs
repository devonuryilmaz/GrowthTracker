namespace GrowthTracker.API.Dtos;

public class TaskCompletionResultDto
{
    public int TaskId { get; set; }
    public DateTime? CompletedAt { get; set; }
}
