using GrowthTracker.API.BackgroundServices;
using GrowthTracker.API.Data;
using GrowthTracker.API.Services;
using Hangfire;
using Hangfire.MemoryStorage;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS yapılandırması
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

builder.Services.AddHttpClient<NotificationService>();

// Background services'ı DI container'a ekle
builder.Services.AddScoped<ReminderJob>();

builder.Services.AddHangfire(config =>
{
    config.SetDataCompatibilityLevel(CompatibilityLevel.Version_170)
          .UseSimpleAssemblyNameTypeSerializer()
          .UseRecommendedSerializerSettings()
          .UseMemoryStorage();
});
builder.Services.AddHangfireServer();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();

// CORS middleware'ini ekle
app.UseCors("AllowAll");

app.UseHangfireDashboard();

app.MapControllers();

// // Uygulama başlatıldıktan sonra recurring job'ı kur
// using (var scope = app.Services.CreateScope())
// {
//     var recurringJobManager = scope.ServiceProvider.GetRequiredService<IRecurringJobManager>();
//     recurringJobManager.AddOrUpdate<ReminderJob>(
//         "SendPendingReminders",
//         job => job.SendPendingReminders(),
//         Cron.Minutely);
// }

app.Run();

