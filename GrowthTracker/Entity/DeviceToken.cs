using System;

namespace GrowthTracker.API.Entity;

public class DeviceToken
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string DeviceId { get; set; }
    public string Token { get; set; }
    public string Platform { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public virtual User User { get; set; }
}
