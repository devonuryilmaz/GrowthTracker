namespace GrowthTracker.API.Dtos;

public class UserSyncRequest
{
    public Guid? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Job { get; set; } = string.Empty;
    public int Age { get; set; }
    public string FocusArea { get; set; } = string.Empty;
}
