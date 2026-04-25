---
agent: agent
description: Projeye yeni bir EF Core entity ekler — POCO sınıfı, AppDbContext DbSet kaydı ve migration oluşturma adımları dahil.
---

# Yeni .NET Entity Ekle

Aşağıdaki adımları sırasıyla uygula.

## Girdi
- **Entity adı** (PascalCase, tekil, ör. `Badge`)
- **Alanlar** — ad, tip, nullable mı?
- **User ile ilişki var mı?** (navigation property gerekiyor mu?)
- **Diğer entity ilişkileri?** (1-N, N-N?)

## Adımlar

### 1. Entity Sınıfı Oluştur
`GrowthTracker/Entity/<X>.cs`:

```csharp
using System;

namespace GrowthTracker.API.Entity;

public class <X>
{
    public int Id { get; set; }

    // -- Alanlar --
    public string Title { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // -- User ilişkisi (gerekiyorsa) --
    public Guid? UserId { get; set; }
    public User? User { get; set; }
}
```

**Kurallar:**
- Primary key: `int Id` (int yeterliyse) veya `Guid Id` (dağıtık / kullanıcı kimliği ise)
- String alanlar: `= string.Empty` ile initialize et, asla `null!` kullanma
- DateTime alanlar: `= DateTime.UtcNow` default
- Navigation property nullable: `User? User`
- Collection navigation: `ICollection<Y> Ys { get; set; } = new List<Y>()`

### 2. AppDbContext'e DbSet Ekle
`GrowthTracker/Data/AppDbContext.cs` dosyasını oku. Mevcut `DbSet<>` satırlarının sonuna ekle:

```csharp
public DbSet<<X>> <X>s { get; set; }
```

### 3. Migration Oluştur
Terminal'de çalıştırılacak komutları göster (sen çalıştırma, kullanıcıya söyle):

```bash
cd GrowthTracker
dotnet ef migrations add Add<X>Entity
dotnet ef database update
```

> **Not:** Migration dosyası otomatik oluşturulur, elle düzenleme gerekmez.

### 4. İlişki Fluent API (gerekiyorsa)
Eğer varsayılan convention yeterli değilse `AppDbContext.cs` içinde `OnModelCreating`'e ekle:

```csharp
modelBuilder.Entity<<X>>()
    .HasOne(x => x.User)
    .WithMany()
    .HasForeignKey(x => x.UserId)
    .OnDelete(DeleteBehavior.Cascade);
```

### 5. User Entity Güncelleme (gerekiyorsa)
Eğer `User`'dan `<X>`'e navigation property gerekiyorsa `GrowthTracker/Entity/User.cs`'e ekle:

```csharp
public ICollection<<X>> <X>s { get; set; } = new List<<X>>();
```

## Kontrol Listesi
- [ ] Entity dosyası `GrowthTracker/Entity/<X>.cs` oluşturuldu
- [ ] Tüm string alanlar `= string.Empty` ile initialize edildi
- [ ] Navigation property'ler nullable `?` ile tanımlandı
- [ ] `AppDbContext.cs`'e `DbSet<<X>>` eklendi
- [ ] Migration komutları kullanıcıya gösterildi
- [ ] Çift yönlü navigation gerekiyorsa ilgili entity güncellendi
