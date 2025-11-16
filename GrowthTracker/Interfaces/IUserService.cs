using System;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Interfaces;

public interface IUserService
{
    public Task<User> CreateUser(User user);
    public Task<User> GetUserById(Guid userId);
}
