using System;
using System.Threading.Tasks;
using GrowthTracker.API.Data;
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
using Microsoft.EntityFrameworkCore;

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

    public async Task<User?> GetUserById(Guid userId)
    {
        return await _context.Users.FindAsync(userId);
    }

    public async Task<User> UpdateUser(Guid userId, UserSyncRequest request)
    {
        var user = await _context.Users.FindAsync(userId)
            ?? throw new KeyNotFoundException($"User {userId} not found.");

        user.Name = request.Name;
        user.Job = request.Job;
        user.Age = request.Age;
        user.FocusArea = request.FocusArea;

        await _context.SaveChangesAsync();
        return user;
    }

    public async Task<User> GetOrCreateUser(UserSyncRequest request)
    {
        // Eğer Id verilmişse, kullanıcıyı bul ve güncelle
        if (request.Id.HasValue)
        {
            var existing = await _context.Users.FindAsync(request.Id.Value);
            if (existing != null)
            {
                existing.Name = request.Name;
                existing.Job = request.Job;
                existing.Age = request.Age;
                existing.FocusArea = request.FocusArea;
                await _context.SaveChangesAsync();
                return existing;
            }
        }

        // Yoksa yeni kullanıcı oluştur
        var user = new User
        {
            Id = request.Id ?? Guid.NewGuid(),
            Name = request.Name,
            Job = request.Job,
            Age = request.Age,
            FocusArea = request.FocusArea
        };

        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
        return user;
    }
}
