namespace GrowthTracker.API.Dtos;

public class TaskSelectionResultDto
{
    public int TaskId { get; set; }
    public int SelectionId { get; set; }
    public DateTime ReminderAt { get; set; }
}
