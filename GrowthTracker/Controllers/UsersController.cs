using GrowthTracker.API.Dtos;
using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        /// <summary>
        /// Kullanıcı yoksa oluştur, varsa güncelle (Upsert).
        /// </summary>
        [HttpPost("sync")]
        public async Task<IActionResult> SyncUser([FromBody] UserSyncRequest request)
        {
            var user = await _userService.GetOrCreateUser(request);
            return Ok(user);
        }

        /// <summary>
        /// Kullanıcı bilgilerini getir.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetUser(Guid id)
        {
            var user = await _userService.GetUserById(id);
            if (user == null)
                return NotFound();
            return Ok(user);
        }
    }
}

