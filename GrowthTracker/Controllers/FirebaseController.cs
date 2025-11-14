using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FirebaseController : ControllerBase
    {
        private readonly IFirebaseService _firebaseService;

        public FirebaseController(IFirebaseService firebaseService)
        {
            _firebaseService = firebaseService;
        }

        [HttpPost("send-notification")]
        public async Task<IActionResult> SendNotification([FromQuery] string deviceToken, [FromQuery] string title, [FromQuery] string body)
        {
            if (string.IsNullOrWhiteSpace(deviceToken) || string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(body))
            {
                return BadRequest("Device token, title, and body are required.");
            }

            await _firebaseService.SendNotificationAsync(deviceToken, title, body);

            return Ok("Notification sent successfully.");
        }
    }
}
