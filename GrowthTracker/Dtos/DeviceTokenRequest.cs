using System;

namespace GrowthTracker.API.Dtos;

public class DeviceTokenRequest
{
    public Guid? UserId { get; set; }
    public string DeviceId { get; set; }
    public string Token { get; set; }
    public string Platform { get; set; }
}
