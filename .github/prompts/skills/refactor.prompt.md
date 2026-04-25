---
agent: agent
description: Seçili kodu GrowthTracker proje kurallarına göre (Clean Architecture, Provider pattern) refactor eder.
---

# Kodu Refactor Et

Verilen kodu proje convention'larına uygun hale getir. Fazladan özellik ekleme; sadece yapıyı düzelt.

## Girdi
- **Refactor edilecek dosya(lar)** — `#file:` ile belirt
- **Sorun ne?** (ör. "controller çok şişman", "provider içinde http çağrısı var", "state ekranda değiştiriliyor")

---

## Flutter Refactor Kuralları

### Provider Kuralı
- HTTP/API çağrıları **sadece** `ApiService` içinde olur
- State mutasyonu **sadece** Provider metodlarında olur, widget içinde değil
- Widget'ta `setState` ile business logic karıştırılmaz

**Yanlış (widget içinde):**
```dart
// YANLIŞ — widget içinde doğrudan http çağrısı
final response = await http.get(...);
setState(() { _data = jsonDecode(response.body); });
```

**Doğru:**
```dart
// DOĞRU — provider üzerinden
await context.read<TaskProvider>().loadTodayTasks(userId);
```

### Provider Erişim Kuralı
- `build()` içinde: `context.watch<X>()` (reaktif)
- Callback/event handler içinde: `context.read<X>()` (aksiyon)
- `Provider.of<X>(context, listen: false)` → `context.read<X>()` ile değiştir

### Widget Boyutu
- 200+ satırlık widget sınıfları alt widget'lara böl
- `_buildSection()` private metodlar yerine `_SectionWidget extends StatelessWidget` tercih et

---

## .NET Refactor Kuralları

### Thin Controller Kuralı
Controller sadece:
1. Request validate et
2. Service metodunu çağır
3. Response döndür

İş mantığı **asla** Controller'da olmaz → Service'e taşı.

**Yanlış:**
```csharp
// YANLIŞ — controller içinde DB sorgusu
var tasks = await _context.DailyTasks.Where(t => t.UserId == id).ToListAsync();
```

**Doğru:**
```csharp
// DOĞRU — service üzerinden
var tasks = await _taskService.GetTasksByUser(id);
```

### Interface Kuralı
Her Service sınıfının bir `I<X>Service` interface'i olmalı.  
Interface yoksa oluştur ve DI kaydını `Program.cs`'te `AddScoped<IXService, XService>()` olarak güncelle.

### EF Core Kuralı
- Sadece okuma yapan sorgular: `.AsNoTracking()` ekle
- `_context` doğrudan Controller'a inject edilmemeli (Service katmanı geçmeli)
- `SaveChangesAsync()` sadece Service içinde çağrılır

### Loglama Kuralı
```csharp
// Bilgi logu — önemli işlemler
_logger.LogInformation("Created {Entity} with id {Id}", nameof(X), result.Id);
// Hata logu — catch bloğunda
_logger.LogError(ex, "Failed to {Action}", "create X");
```

---

## Refactor Adımları

1. **Hedef dosyayı oku** — mevcut kod yapısını anla
2. **Sorunları listele** — convention ihlallerini çıkar
3. **Değişiklikleri uygula** — minimum diff, sadece gerekli değişiklikler
4. **Bağımlı dosyaları güncelle** — interface değiştiyse implementasyon, DI kaydı vs.
5. **Davranış değişmediğini doğrula** — refactor sonrası public API aynı kalmalı

## Kontrol Listesi
- [ ] İş mantığı service katmanında
- [ ] Controller yalnızca routing/validation/response
- [ ] Provider state mutasyonu sadece provider içinde
- [ ] Flutter widget'ta `context.read` vs `context.watch` doğru kullanılıyor
- [ ] .NET servis interface'i var ve DI kayıtlı
- [ ] AsNoTracking read-only sorgularda uygulandı
- [ ] Davranış değişmedi (public method imzaları aynı)
