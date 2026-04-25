---
applyTo: "**"
---

# GrowthTracker — Proje Bağlamı

Bu proje iki bileşenden oluşur: bir **Flutter mobil uygulaması** ve bir **.NET 9 REST API**. Her kod değişikliğinde bu bağlamı dikkate al.

---

## Flutter Uygulaması (`growth_tracker/`)

**Dil & SDK:** Dart, Flutter  
**State Management:** Provider (ChangeNotifier) — `context.read<XProvider>()` / `context.watch<XProvider>()`  
**API İletişim:** `lib/services/api_service.dart` üzerinden HTTP (dart:io http paketi)  
**Push Bildirim:** Firebase Messaging + flutter_local_notifications  
**Kalıcı Veri:** SharedPreferences  
**UI:** Material Design, google_fonts, table_calendar, confetti

### Klasör Yapısı
```
lib/
  main.dart              — MultiProvider kurulumu + MaterialApp
  screens/               — *_screen.dart (StatefulWidget veya StatelessWidget)
  providers/             — *_provider.dart (ChangeNotifier subclass)
  models/                — *_model.dart veya düz sınıf, JSON serialization
  services/              — api_service.dart, notification_service.dart
  firebase/              — Firebase helper
  theme/                 — app_theme.dart
  helper/                — yardımcı fonksiyonlar
```

### Naming Kuralları (Flutter)
- Dosyalar: `snake_case` (ör. `task_detail_screen.dart`)
- Sınıflar: `PascalCase` (ör. `TaskDetailScreen`)
- Widget state: `_PascalCaseState`
- Provider metodları: `camelCase`, async olanlar `Future<void>` döner ve `notifyListeners()` çağırır
- Private alanlar: `_camelCase` (ör. `_isLoading`, `_error`)

### Provider Şablonu
Her Provider:
1. Private state alanları + getter'lar
2. `bool _isLoading` ve `String? _error` alanları zorunlu
3. `notifyListeners()` her state değişiminde çağrılır
4. `ApiService _api = ApiService()` ile servis erişimi

### Ekran Şablonu
- `StatefulWidget` veya `StatelessWidget`
- `Provider.of<XProvider>(context, listen: false)` yerine `context.read<XProvider>()` kullan
- `context.watch<XProvider>()` reactive okuma için
- Scaffold → AppBar → Body pattern

---

## .NET API (`GrowthTracker/`)

**Framework:** ASP.NET Core 9.0  
**ORM:** Entity Framework Core 9.0 + Npgsql (PostgreSQL)  
**Background Jobs:** Hangfire + Hangfire.PostgreSQL  
**AI:** OpenAI SDK (gpt-4o)  
**Push:** FirebaseAdmin SDK  
**Docs:** Swagger/Swashbuckle  
**Namespace root:** `GrowthTracker.API`

### Klasör Yapısı
```
GrowthTracker/
  Controllers/           — *Controller.cs ([Route("api/[controller]")], [ApiController])
  Services/              — *Service.cs (interface implementasyonu)
  Interfaces/            — I*Service.cs
  Entity/                — POCO sınıflar (EF Core entity)
  Data/                  — AppDbContext.cs
  Dtos/                  — *Dto.cs, *Request.cs (input/output şekilleri)
  BackgroundServices/    — *Job.cs (Hangfire recurring job)
  Migrations/            — EF Core otomatik migration dosyaları
```

### Naming Kuralları (.NET)
- `PascalCase` her yerde
- Controller: `XController` (`[Route("api/[controller]")]`, `[ApiController]`)
- Service: `XService`, interface `IXService`
- Entity: düz POCO, `int Id` veya `Guid Id` primary key
- DTO: `XDto`, `XRequest`
- Background job: `XJob`

### Dependency Injection Düzeni
`Program.cs` içinde kayıt: `builder.Services.AddScoped<IXService, XService>()`  
Constructor injection: tüm bağımlılıklar constructor parametresi olarak alınır.

### Controller Şablonu
```csharp
[Route("api/[controller]")]
[ApiController]
public class XController : ControllerBase
{
    private readonly IXService _xService;
    private readonly ILogger<XController> _logger;

    public XController(IXService xService, ILogger<XController> logger)
    {
        _xService = xService;
        _logger = logger;
    }
}
```

### Entity Şablonu
```csharp
namespace GrowthTracker.API.Entity;
public class X
{
    public int Id { get; set; }
    // ... alanlar
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    // Navigation property varsa:
    public Guid? UserId { get; set; }
    public User? User { get; set; }
}
```

---

## API İletişim Deseni

**Base URL:** `http://localhost:5058/api`  
**Format:** JSON (REST)  
**CORS:** AllowAll policy aktif

Flutter → API çağrısı her zaman `ApiService` üzerinden yapılır, doğrudan `http.get/post` ekran içinde kullanılmaz.

---

## Genel Prensipler

- **Asla** doğrudan `AppDbContext` ekran veya controller'a inject etme — service layer kullan.
- Flutter'da state mutasyonu sadece Provider metodlarında yapılır, widget içinde değil.
- Tüm async işlemler try/catch ile sarılır; hata `_error` alanına atanır.
- EF Core sorguları read-only ise `AsNoTracking()` kullanılır.
- Yeni entity eklendiğinde mutlaka `AppDbContext.cs`'e `DbSet<X>` ve migration eklenir.
