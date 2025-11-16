using System;

namespace GrowthTracker.API.Entity;

public class User
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string Job { get; set; }
    public int Age { get; set; }
}
