# 🌱 GrowthTracker API

Modern hatırlatıcı ve kişisel gelişim takip sistemi için geliştirilmiş RESTful API.

## 📋 İçindekiler

- [Özellikler](#özellikler)
- [Teknolojiler](#teknolojiler)
- [Kurulum](#kurulum)
- [Yapılandırma](#yapılandırma)
- [API Endpoints](#api-endpoints)
- [Veritabanı](#veritabanı)
- [Background Jobs](#background-jobs)
- [Geliştirme](#geliştirme)
- [Katkıda Bulunma](#katkıda-bulunma)

## ✨ Özellikler

- 🔔 **Akıllı Hatırlatıcılar**: Zamanlı hatırlatıcı sistemi
- 📱 **Push Bildirimler**: Firebase Cloud Messaging entegrasyonu
- ⏰ **Otomatik İşlemler**: Hangfire ile background job yönetimi
- 🗄️ **PostgreSQL**: Güvenilir veri saklama
- 🌐 **CORS Desteği**: Cross-origin resource sharing
- 📊 **Swagger/OpenAPI**: Otomatik API dokümantasyonu
- 🏗️ **Clean Architecture**: Temiz kod prensiplerine uygun yapı

## 🛠️ Teknolojiler

- **.NET 9.0** - Web API framework
- **Entity Framework Core 9.0** - ORM
- **PostgreSQL** - Veritabanı
- **Hangfire** - Background job processing
- **Swagger/OpenAPI** - API dokümantasyonu
- **Serilog** - Structured logging

## 🚀 Kurulum

### Gereksinimler

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [PostgreSQL 12+](https://www.postgresql.org/download/)
- IDE: Visual Studio 2022 veya Visual Studio Code

### Adım Adım Kurulum

1. **Projeyi klonlayın**
   ```bash
   git clone https://github.com/kullaniciadi/GrowthTracker.git
   cd GrowthTracker
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   dotnet restore
   ```

3. **Veritabanını oluşturun**
   ```bash
   # PostgreSQL'de veritabanı oluşturun
   createdb GrowthTrackerDb
   ```

4. **Migration'ları uygulayın**
   ```bash
   dotnet ef database update
   ```

5. **Uygulamayı çalıştırın**
   ```bash
   dotnet run
   ```

## ⚙️ Yapılandırma

### appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=GrowthTrackerDb;Username=postgres;Password=your_password"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Ortam Değişkenleri

Geliştirme ortamında `appsettings.Development.json` dosyasını kullanabilirsiniz:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=GrowthTrackerDb_Dev;Username=postgres;Password=dev_password"
  }
}
```

## 🔌 API Endpoints

### Hatırlatıcılar (Reminders)

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/reminders/upcoming?days=7` | Yaklaşan hatırlatıcıları getir |
| POST | `/api/reminders` | Yeni hatırlatıcı oluştur |
| PUT | `/api/reminders/{id}/complete` | Hatırlatıcıyı tamamla |
| DELETE | `/api/reminders/{id}` | Hatırlatıcıyı sil |

### Örnek Kullanım

#### Yeni Hatırlatıcı Oluşturma
```bash
curl -X POST "https://localhost:7000/api/reminders" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Spor yapmayı unutma",
    "description": "Günlük 30 dakika yürüyüş",
    "reminderDate": "2025-10-27T09:00:00Z"
  }'
```

#### Yaklaşan Hatırlatıcıları Getirme
```bash
curl -X GET "https://localhost:7000/api/reminders/upcoming?days=7"
```

## 🗄️ Veritabanı

### Entity Framework Komutları

```bash
# Yeni migration oluştur
dotnet ef migrations add MigrationName

# Veritabanını güncelle
dotnet ef database update

# Migration'ı geri al
dotnet ef database update PreviousMigrationName

# Veritabanını sıfırla
dotnet ef database drop
```

### Veri Modelleri

#### Reminder
```csharp
public class Reminder
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public DateTime ReminderDate { get; set; }
    public bool IsCompleted { get; set; }
}
```

## ⚡ Background Jobs

Hangfire kullanarak otomatik görevler:

- **SendPendingReminders**: Her dakika çalışır, zamanı gelen hatırlatıcıları gönderir
- **Dashboard**: `/hangfire` adresinden Hangfire dashboard'una erişilebilir

## 🔧 Geliştirme

### Projeyi Build Etme
```bash
dotnet build
```

### Test Çalıştırma
```bash
dotnet test
```

### Code Coverage
```bash
dotnet test --collect:"XPlat Code Coverage"
```

### Docker ile Çalıştırma (Opsiyonel)
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["GrowtTracker.API.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GrowtTracker.API.dll"]
```

## 📚 Dokümantasyon

- **Swagger UI**: `https://localhost:7000/swagger` - API dokümantasyonu
- **Hangfire Dashboard**: `https://localhost:7000/hangfire` - Background job yönetimi

## 🐛 Hata Ayıklama

### Yaygın Sorunlar

1. **PostgreSQL Bağlantı Hatası**
   - PostgreSQL servisinin çalıştığından emin olun
   - Connection string'i kontrol edin

2. **Migration Hatası**
   ```bash
   dotnet ef database drop
   dotnet ef database update
   ```

3. **CORS Hatası**
   - `Program.cs`'te CORS yapılandırmasının doğru olduğunu kontrol edin

## 🤝 Katkıda Bulunma

1. Fork'layın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit'leyin (`git commit -m 'Add amazing feature'`)
4. Push'layın (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.


## 🙏 Teşekkürler

- Microsoft .NET Team
- PostgreSQL Community
- Hangfire Contributors

---

⭐ **Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!**