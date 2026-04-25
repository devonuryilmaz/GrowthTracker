---
agent: agent
description: Projeye tam bir .NET API endpoint'i ekler — Controller action, IService interface, Service implementasyonu ve DI kaydı dahil.
---

# Yeni .NET API Endpoint Scaffold Et

Aşağıdaki adımları sırasıyla uygula. Her dosyayı oluşturmadan önce mevcut benzer dosyaları referans al.

## Girdi
Eklenecek endpoint için:
- **İşlev** (ör. "Kullanıcının geçmiş görevlerini getir")
- **HTTP metodu** (GET / POST / PUT / DELETE)
- **Route** (ör. `/api/dailyTasks/history`)
- **Yeni entity gerekiyor mu?** (Evet → önce `add-net-entity` prompt'unu çalıştır)
- **Yeni Controller mı, mevcut Controller'a mı ekleniyor?**

## Adımlar

### 1. DTO Tanımla (gerekiyorsa)
`GrowthTracker/Dtos/` altında:
- Input: `<X>Request.cs`
- Output: `<X>Dto.cs`

```csharp
namespace GrowthTracker.API.Dtos;

public class <X>Request
{
    public string PropertyName { get; set; } = string.Empty;
}
```

### 2. Interface Güncelle veya Oluştur
`GrowthTracker/Interfaces/I<X>Service.cs`:

```csharp
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;

namespace GrowthTracker.API.Interfaces;

public interface I<X>Service
{
    Task<<ReturnType>> <MethodName>(<parametreler>);
}
```

Mevcut interface varsa sadece yeni method imzasını ekle.

### 3. Service Implementasyonu
`GrowthTracker/Services/<X>Service.cs`:

```csharp
using GrowthTracker.API.Data;
using GrowthTracker.API.Dtos;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace GrowthTracker.API.Services;

public class <X>Service : I<X>Service
{
    private readonly AppDbContext _context;
    private readonly ILogger<<X>Service> _logger;

    public <X>Service(AppDbContext context, ILogger<<X>Service> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<<ReturnType>> <MethodName>(<parametreler>)
    {
        // Read-only sorgularda AsNoTracking() kullan
        // _logger.LogInformation(...)
    }
}
```

### 4. Controller Action Ekle veya Oluştur
Mevcut Controller'a ekliyorsan sadece action metodunu ekle.  
Yeni Controller oluşturuyorsan `GrowthTracker/Controllers/<X>Controller.cs`:

```csharp
using GrowthTracker.API.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GrowthTracker.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class <X>Controller : ControllerBase
{
    private readonly I<X>Service _<x>Service;
    private readonly ILogger<<X>Controller> _logger;

    public <X>Controller(I<X>Service <x>Service, ILogger<<X>Controller> logger)
    {
        _<x>Service = <x>Service;
        _logger = logger;
    }

    [Http<Method>("<route-suffix>")]
    public async Task<IActionResult> <ActionName>([From<Query|Body|Route>] <Type> param)
    {
        var result = await _<x>Service.<MethodName>(param);
        return Ok(result);
    }
}
```

### 5. DI Kaydı
`GrowthTracker/Program.cs` içinde `builder.Services.Add*` bölümüne ekle:

```csharp
builder.Services.AddScoped<I<X>Service, <X>Service>();
```

### 6. Doğrulama
- `GrowthTracker/GrowthTracker.API.csproj` namespace ve dosya referanslarını kontrol et
- EF Core entity değiştiyse migration gerektiğini belirt

## Kontrol Listesi
- [ ] DTO(lar) oluşturuldu
- [ ] Interface tanımlandı / güncellendi
- [ ] Service implemente edildi (AsNoTracking + loglama)
- [ ] Controller action eklendi ([ApiController], doğru HTTP verb)
- [ ] DI kaydı Program.cs'e eklendi
- [ ] Migration gereksinimi değerlendirildi
