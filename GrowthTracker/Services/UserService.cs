using System;
using System.Threading.Tasks;
using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;

namespace GrowthTracker.API.Services;

public class UserService : IUserService
{
    private readonly AppDbContext _context;

    public UserService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<User> CreateUser(User user)
    {
        _ = await _context.Users.AddAsync(user);
        _ = await _context.SaveChangesAsync();

        return user;
    }

    public async Task<User> GetUserById(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        return user;
    }
}
