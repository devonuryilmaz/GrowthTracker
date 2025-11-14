using System;

namespace GrowthTracker.API.Interfaces;

public interface IDeviceTokenService
{
    Task SaveDeviceTokenAsync(Guid? userId, string deviceId, string token, string platform);
}
