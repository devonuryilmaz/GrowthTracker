using System;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using GrowthTracker.API.Interfaces;

namespace GrowthTracker.API.Services;

public class FirebaseService : IFirebaseService
{
    private static bool _isInitialized = false;

    public FirebaseService()
    {
        if (!_isInitialized)
        {
            // Initialize Firebase Admin SDK here
            FirebaseApp.Create(new AppOptions()
            {
                Credential = GoogleCredential.FromServiceAccountCredential(
                    ServiceAccountCredential.FromServiceAccountData(
                        File.OpenRead("Secrets/firebase-adminsdk.json"))),
            });

            _isInitialized = true;
        }
    }


    public async Task SendNotificationAsync(string deviceToken, string title, string body)
    {
        var message = new Message()
        {
            Token = deviceToken,
            Notification = new Notification
            {
                Title = title,
                Body = body
            }
        };

        await FirebaseMessaging.DefaultInstance.SendAsync(message);
    }
}
