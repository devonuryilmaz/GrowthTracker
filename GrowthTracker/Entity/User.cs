using System;

namespace GrowthTracker.API.Entity;

public class User
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string Job { get; set; }
    public int Age { get; set; }
    public string FocusArea { get; set; } = string.Empty;

    public ICollection<DailyTask> DailyTasks { get; set; } = new List<DailyTask>();
    public ICollection<TaskSelection> TaskSelections { get; set; } = new List<TaskSelection>();
}
