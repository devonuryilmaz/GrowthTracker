using System;
using Microsoft.EntityFrameworkCore;
using GrowthTracker.API.Models;

namespace GrowthTracker.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

   public DbSet<Reminder> Reminders { get; set; }

}

