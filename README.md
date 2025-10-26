# 🌱 GrowthTracker - Kişisel Gelişim Platform Ekosistemi

Modern, full-stack kişisel gelişim ve hatırlatıcı platform ekosistemi. .NET Backend API ve Flutter Mobile App'den oluşan kapsamlı bir çözüm.

## 🏗️ Proje Mimarisi

```
GrowthTracker/
├── 🔧 GrowthTracker/          # .NET 9.0 Web API (Backend)
├── 📱 growth_tracker/         # Flutter Mobile Application  
├── 📄 GrowthTracker.sln       # Visual Studio Solution (.NET API)
└── 📖 README.md               # Bu dosya
```

## 📦 Projeler

### 🔧 Backend API (`GrowthTracker/`)
- **.NET 9.0** Web API
- **PostgreSQL** veritabanı
- **Entity Framework Core** ORM
- **Hangfire** background jobs
- **Swagger/OpenAPI** dokümantasyon

**Özellikler:**
- ✅ RESTful API endpoints
- ✅ Zamanlı hatırlatıcı sistemi
- ✅ Push bildirim desteği
- ✅ Otomatik background işlemler
- ✅ CORS yapılandırması

### 🎨 Frontend (`growth_tracker/`)
- Modern frontend framework
- Responsive tasarım
- API entegrasyonu
- Kullanıcı dostu arayüz

## 🚀 Hızlı Başlangıç

### Gereksinimler
- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [PostgreSQL 12+](https://www.postgresql.org/download/)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Mobile app için)
- [Git](https://git-scm.com/)

### 1. Repository'yi Klonlayın
```bash
git clone https://github.com/[kullanici-adi]/GrowthTracker.git
cd GrowthTracker
```

### 2. Backend Kurulumu (.NET API)
```bash
cd GrowthTracker
dotnet restore
dotnet ef database update
dotnet run
```
🌐 API: `https://localhost:7000`

### 3. Mobile App Kurulumu (Flutter)
```bash
cd ../growth_tracker
flutter pub get
flutter run
```
📱 Mobile App: Emulator/Device'da çalışır

## 🔧 Geliştirme Ortamı

### Backend Development (.NET API)
```bash
cd GrowthTracker
dotnet watch run
```

### Mobile App Development (Flutter)
```bash
cd growth_tracker
flutter run --hot-reload
```

### Visual Studio Solution
```bash
# Ana dizinde solution dosyası ile çalışmak için
cd GrowthTracker
start GrowthTracker.sln  # Visual Studio'da açar
```

### Veritabanı Yönetimi
```bash
# Yeni migration
dotnet ef migrations add MigrationName

# Veritabanını güncelle
dotnet ef database update

# Hangfire Dashboard
# https://localhost:7000/hangfire
```

## 📚 API Dokümantasyonu

- **Swagger UI**: `https://localhost:7000/swagger`
- **OpenAPI Spec**: `https://localhost:7000/swagger/v1/swagger.json`

### Ana Endpoints
- `GET /api/reminders/upcoming` - Yaklaşan hatırlatıcılar
- `POST /api/reminders` - Yeni hatırlatıcı oluştur
- `PUT /api/reminders/{id}/complete` - Hatırlatıcıyı tamamla
- `DELETE /api/reminders/{id}` - Hatırlatıcıyı sil

## 🛠️ Teknoloji Stack'i

### Backend
- **Framework**: ASP.NET Core 9.0
- **Database**: PostgreSQL
- **ORM**: Entity Framework Core
- **Background Jobs**: Hangfire
- **Documentation**: Swagger/OpenAPI
- **Logging**: Built-in ASP.NET Core Logging

### Mobile App
- **Framework**: Flutter
- **Language**: Dart
- **Platforms**: iOS, Android, Web, Desktop
- **UI**: Material Design & Cupertino
- **State Management**: [Belirtilmeli - Provider/Bloc/Riverpod]
- **HTTP Client**: Dio/http package

### DevOps & Tools
- **Version Control**: Git
- **Container**: Docker support
- **IDE**: Visual Studio 2022, VS Code
- **Database Tools**: pgAdmin, EF Core Tools

## 🏗️ Proje Yapısı

```
GrowthTracker/
├── GrowthTracker/                 # Backend API (.NET 9.0)
│   ├── Controllers/               # API Controllers
│   ├── Models/                    # Data Models
│   ├── Data/                      # Database Context
│   ├── Services/                  # Business Logic
│   ├── BackgroundServices/        # Hangfire Jobs
│   ├── Migrations/               # EF Migrations
│   └── Program.cs                # Entry Point
├── growth_tracker/               # Flutter Mobile App
│   ├── lib/                      # Dart Source Code
│   │   ├── models/               # Data Models
│   │   ├── services/             # API Services
│   │   ├── screens/              # UI Screens
│   │   ├── widgets/              # Reusable Widgets
│   │   └── main.dart             # Entry Point
│   ├── android/                  # Android specific files
│   ├── ios/                      # iOS specific files
│   └── pubspec.yaml              # Flutter Dependencies
├── .gitignore                    # Git Ignore Rules
├── GrowthTracker.sln            # Visual Studio Solution
└── README.md                    # This File
```

## 🔄 CI/CD Pipeline

### GitHub Actions (Önerilen)
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline
on: [push, pull_request]
jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '9.0.x'
      - run: dotnet build ./GrowthTracker
      - run: dotnet test ./GrowthTracker
  
  mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
        working-directory: ./growth_tracker
      - run: flutter test
        working-directory: ./growth_tracker
      - run: flutter build apk
        working-directory: ./growth_tracker
```

## 🐳 Docker Desteği

### Backend Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY . .
EXPOSE 80
ENTRYPOINT ["dotnet", "GrowtTracker.API.dll"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  api:
    build: ./GrowthTracker
    ports:
      - "7000:80"
    depends_on:
      - postgres
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: GrowthTrackerDb
      POSTGRES_PASSWORD: postgres
```

## 🤝 Katkıda Bulunma

1. 🍴 **Fork** edin
2. 🌿 **Feature branch** oluşturun (`git checkout -b feature/amazing-feature`)
3. 💾 **Commit** edin (`git commit -m 'Add amazing feature'`)
4. 📤 **Push** edin (`git push origin feature/amazing-feature`)
5. 🎯 **Pull Request** açın

### Geliştirme Kuralları
- ✅ Clean Code prensiplerini takip edin
- ✅ Unit testler yazın
- ✅ API değişikliklerini dokümante edin
- ✅ Commit mesajlarını anlamlı yazın

## 📊 Proje Durumu

- ✅ **Backend API**: Functional (.NET 9.0)
- ✅ **Database**: PostgreSQL setup
- ✅ **Background Jobs**: Hangfire integration
- ✅ **Documentation**: Swagger/OpenAPI
- ✅ **Mobile App**: Flutter project structure
- 🔄 **API Integration**: In progress
- 🔄 **Tests**: In progress
- 🔄 **CI/CD**: Planning


## 📞 İletişim & Destek

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/devonuryilmaz/GrowthTracker/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/devonuryilmaz/GrowthTracker/discussions)
- 📧 **Email**: onuryilmaz.cbu@gmail.com
- 💬 **LinkedIn**: [linkedin.com/in/onuryilmazdev](https://linkedin.com/in/onuryilmazdev)
- 🐦 **Twitter/X**: [@devonuryilmaz](https://twitter.com/devonuryilmaz)

## 📄 Lisans

Bu proje [MIT License](LICENSE) altında lisanslanmıştır.

## 🙏 Teşekkürler

- Microsoft .NET Team
- PostgreSQL Community
- Hangfire Contributors
- Open Source Community

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın! ⭐**

[🌐 Live Demo](https://growthtracker.example.com) | [📚 Documentation](https://docs.growthtracker.example.com) | [🎯 Roadmap](https://github.com/kullanici/GrowthTracker/projects)

</div>