using System;

namespace GrowthTracker.API.Interfaces;

public interface IFirebaseService
{
    Task SendNotificationAsync(string deviceToken, string title, string body);
}
