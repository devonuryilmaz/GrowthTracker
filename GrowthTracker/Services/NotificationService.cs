using System;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace GrowthTracker.API.Services;

public class NotificationService
{
    private readonly HttpClient _httpClient;

    public NotificationService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task SendNotificationAsync(string fcmToken, string title, string body)
    {
        var notification = new
        {
            to = fcmToken,
            notification = new
            {
                title,
                body
            }
        };

        var json = JsonSerializer.Serialize(notification);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("key", "YOUR_SERVER_KEY");

        var response = await _httpClient.PostAsync("https://fcm.googleapis.com/fcm/send", content);
        response.EnsureSuccessStatusCode();
    }
}
