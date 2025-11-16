using System;
using Microsoft.EntityFrameworkCore;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Reminder> Reminders { get; set; }
    public DbSet<DailyTask> DailyTasks { get; set; }
    public DbSet<DeviceToken> DeviceTokens { get; set; }
    public DbSet<User> Users { get; set; }
}

