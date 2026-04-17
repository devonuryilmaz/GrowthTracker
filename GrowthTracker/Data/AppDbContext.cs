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
    public DbSet<TaskSelection> TaskSelections { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // DailyTask → User (optional FK, nullable UserId)
        modelBuilder.Entity<DailyTask>()
            .HasOne(t => t.User)
            .WithMany(u => u.DailyTasks)
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.SetNull);

        // TaskSelection → User
        modelBuilder.Entity<TaskSelection>()
            .HasOne(ts => ts.User)
            .WithMany(u => u.TaskSelections)
            .HasForeignKey(ts => ts.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Reminder → User (optional)
        modelBuilder.Entity<Reminder>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.SetNull);

        // Reminder → DailyTask (optional)
        modelBuilder.Entity<Reminder>()
            .HasOne(r => r.DailyTask)
            .WithMany()
            .HasForeignKey(r => r.DailyTaskId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

