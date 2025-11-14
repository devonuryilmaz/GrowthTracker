using System;
using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;

namespace GrowthTracker.API.Services;

public class DeviceTokenService : IDeviceTokenService
{
    private readonly AppDbContext _context;
    public DeviceTokenService(AppDbContext context)
    {
        _context = context;
    }

    public async Task SaveDeviceTokenAsync(Guid? userId, string deviceId, string token, string platform)
    {
        var existingToken = _context.DeviceTokens
            .FirstOrDefault(dt => dt.DeviceId == deviceId && dt.Platform == platform);

        if (existingToken != null)
        {
            existingToken.Token = token;
            existingToken.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
        else
        {
            var deviceToken = new DeviceToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                DeviceId = deviceId,
                Token = token,
                Platform = platform,
                CreatedAt = DateTime.UtcNow
            };

            await _context.DeviceTokens.AddAsync(deviceToken);
            await _context.SaveChangesAsync();
        }
    }   
}