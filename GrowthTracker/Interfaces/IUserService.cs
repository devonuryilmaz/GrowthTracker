using System;
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Interfaces;

public interface IUserService
{
    Task<User> CreateUser(User user);
    Task<User?> GetUserById(Guid userId);
    Task<User> UpdateUser(Guid userId, UserSyncRequest request);
    Task<User> GetOrCreateUser(UserSyncRequest request);
}
