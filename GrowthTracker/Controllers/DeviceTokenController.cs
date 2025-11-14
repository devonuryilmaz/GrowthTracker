using GrowthTracker.API.Dtos;
using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GrowtTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DeviceTokenController : ControllerBase
    {
        private readonly IDeviceTokenService _deviceTokenService;

        public DeviceTokenController(IDeviceTokenService deviceTokenService)
        {
            _deviceTokenService = deviceTokenService;
        }

        [HttpPost]
        public async Task<IActionResult> SaveDeviceToken([FromBody] DeviceTokenRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.DeviceId) || string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.Platform))
            {
                return BadRequest("Invalid device token data.");
            }

            await _deviceTokenService.SaveDeviceTokenAsync(request.UserId, request.DeviceId, request.Token, request.Platform);

            return Ok();
        }
    }
}
