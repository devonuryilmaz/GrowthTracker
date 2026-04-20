# GrowthTracker — Yol Haritası & İş Takip Dokümanı

> **Vizyon:** Her meslek grubuna hitap eden, AI destekli Kişisel Gelişim Koçu.  
> **Son Güncelleme:** 20 Nisan 2026

---

## 📊 Mevcut Durum Analizi

### Backend (.NET 9 + PostgreSQL + Hangfire + Firebase)
| Bileşen | Durum | Not |
|---------|-------|-----|
| User entity | ✅ Var | `Name`, `Job`, `Age`, `FocusArea` — tam |
| DailyTask entity | ✅ Var | `Title`, `Description`, `IsCompleted`, `UserId`, `Category`, `EstimatedMinutes`, `IsSelected`, `CompletedAt` — tam |
| OpenAI entegrasyonu | ✅ Var | Türkçe 3'lü JSON Array döndürüyor; `GenerateTaskSuggestionsAsync` + `GenerateTaskExamplesAsync` (4 örnek) |
| AIGeneratorJob (Hangfire) | ✅ Aktif | Günlük çalışıyor, 3 görev kaydediyor, idempotent kontrol var |
| ReminderJob | ✅ Aktif | Program.cs'de aktif, gerçek DeviceToken tablosundan çekiyor |
| UsersController | ✅ Var | `POST /api/users/sync` ve `GET /api/users/{id}` endpoint'leri mevcut |
| AIController | ✅ Var | `GET /api/ai/suggestions` + yeni `GET /api/ai/task-examples?taskId&userId` endpoint'i |
| DailyTasksController | ✅ Var | `today`, `select`, `complete`, `history`, `stats`, `from-suggestion` — tam |
| TaskSelection yapısı | ✅ Var | Entity, endpoint ve servis tam olarak implement edildi |
| Görev tamamlama endpoint'i | ✅ Var | `POST /api/dailytasks/{id}/complete` çalışıyor |
| IUserService | ✅ Tam | `Create`, `GetById`, `Update`, `GetOrCreate` metotları var |
| NotificationService/FirebaseService | ⚠️ Ayrı | İki servis hâlâ ayrı; `NotificationService` dead code (`"YOUR_SERVER_KEY"` hardcoded), birleştirme yapılmadı (FAZ 4.5) |

### Flutter (Dart)
| Bileşen | Durum | Not |
|---------|-------|-----|
| Login/Onboarding | ✅ Var | Ad, Yaş, Meslek, Odak Alanı (6 kategori) — çok adımlı |
| Home Screen | ✅ Var | Selamlama, aktif görev kartı, geri sayım timer, tamamlama butonu |
| Task Detail Screen | ✅ Yeni | `TaskDetailScreen` — AI örnekleri (`task-examples` endpoint), görev detayı, "Başla" butonu |
| AddReminder Screen | ⚠️ Orphaned | Ekran mevcut ama `MainShell`'e bağlı değil — erişilemiyor |
| State Management | ✅ Var | `provider` paketi, `UserProvider` + `TaskProvider` + `StatsProvider` |
| User modeli | ✅ Var | `lib/models/user_model.dart` — tam model |
| DailyTask / AI Task modeli | ✅ Var | `lib/models/daily_task.dart`, `lib/models/task_selection.dart` |
| Task Discovery ekranı | ✅ Var | 3 TaskCard, shimmer yükleme, seçim → TaskDetail → Home yönlendirme |
| Aktif Görev paneli | ✅ Var | HomeScreen'de geri sayım timer ile aktif görev paneli |
| Journey / Stats ekranı | ⚠️ Kısmi | Ekran var, API bağlantısı var; `fl_chart` ve `table_calendar` **eksik** — custom canvas ile çizilmiş |
| Ayarlar ekranı | ⚠️ Kısmi | Profil düzenleme var; bildirim/dark mode toggle'ları UI'da var fakat **persist edilmiyor** |
| Backend'e user sync | ✅ Var | Onboarding ve Settings'ten `POST /api/users/sync` çağrılıyor |
| DeviceToken kaydı | ⚠️ Hata | `sendTokenToServer` `userId: null` gönderiyor — push notification ReminderJob için token kullanıcıya bağlanamıyor |
| Görev tamamlama feedback | ⚠️ Eksik | Tamamlama butonu var, `confetti` paketi **pubspec'e eklenmedi** |
| Named Routes | ⚠️ Eksik | `MaterialPageRoute` kullanılıyor, `MaterialApp.routes` tanımlanmadı |
| Flutter NotificationService | ⚠️ Unused | `lib/services/notification_service.dart` mevcut ama hiçbir yerden çağrılmıyor |

---

## 🗺️ Fazlar & İş Kalemleri

---

### FAZ 1 — Backend Veri Modeli & API Temeli
> **Hedef:** AI'ın 3 görev üretip kullanıcıya sunabilmesi için backend altyapısını hazırla.

- [x] **1.1** `User` entity'ye `FocusArea` (string) alanı ekle
- [x] **1.2** `DailyTask` entity'yi genişlet:
  - `UserId` (Guid, FK → User)
  - `Category` (string — Kariyer, Sağlık, Zihin vb.)
  - `EstimatedMinutes` (int)
  - `IsSelected` (bool — kullanıcı bu görevi seçti mi)
  - `CompletedAt` (DateTime? — tamamlanma zamanı)
- [x] **1.3** `TaskSelection` entity oluştur:
  - `Id`, `UserId`, `DailyTaskId`, `SelectedAt`, `CompletedAt`, `Status` (Pending/Active/Completed/Skipped)
- [x] **1.4** Migration oluştur ve uygula *(oluşturulan migration: `20260417060000_UpdateModel` — tüm entity değişikliklerini kapsamaktadır)*
- [x] **1.5** `AppDbContext`'e yeni DbSet'leri ekle, FK ilişkilerini `OnModelCreating` ile tanımla

---

### FAZ 2 — Backend API Endpoint'leri
> **Hedef:** Flutter'ın ihtiyaç duyduğu tüm CRUD + iş mantığı endpoint'lerini aç.

- [x] **2.1** `UsersController` — Kullanıcı senkronizasyon endpoint'leri:
  - `POST /api/users/sync` — Upsert (yoksa oluştur, varsa güncelle: Name, Job, Age, FocusArea)
  - `GET /api/users/{id}` — Kullanıcı bilgilerini getir
- [x] **2.2** `IUserService` + `UserService`'e `UpdateUser` ve `GetOrCreateUser` metotları ekle
- [x] **2.3** `AIController` — Görev önerileri:
  - `GET /api/ai/suggestions?userId={id}` → 3 görev içeren JSON Array döndür
  - `GET /api/ai/task-examples?taskId={id}&userId={id}` → Seçilen görev için 4 somut örnek döndür *(yeni)*
- [x] **2.4** `DailyTasksController` — Görev seçim & tamamlama:
  - `GET /api/dailytasks/today?userId={id}` — Kullanıcının bugünkü 3 önerisini getir
  - `POST /api/dailytasks/{id}/select` — Kullanıcının seçtiği görevi işaretle
  - `POST /api/dailytasks/{id}/complete` — Görevi tamamlandı olarak işaretle
  - `GET /api/dailytasks/history?userId={id}&days=30` — Geçmiş tamamlanan görevler
- [x] **2.5** Completion istatistik endpoint'i:
  - `GET /api/dailytasks/stats?userId={id}` — Kategoriye göre tamamlanan görev sayıları
- [x] **2.6** `POST /api/dailytasks/from-suggestion` — AI önerisinden direkt görev oluştur *(yeni)*

---

### FAZ 3 — OpenAI Prompt Revizyonu & AI Job Güncellemesi
> **Hedef:** AI'ın 3 farklı kategoride, yapılandırılmış JSON formatında görev üretmesini sağla.

- [x] **3.1** `OpenAIService.GenerateTaskSuggestionsAsync` prompt'unu revize et:
  - Kullanıcının `FocusArea`'sını prompt'a dahil et
  - 3 farklı kategoride görev iste (ör. kullanıcının odak alanı + 2 tamamlayıcı)
  - Çıktı formatı: JSON Array `[{title, description, category, estimatedMinutes}]`
  - `response_format: json_object` parametresini kullan
  - MaxOutputTokenCount'u 200'den ~600'e çıkar
- [x] **3.2** `OpenAIService`'in dönüş tipini `string` → `List<TaskSuggestionDto>` DTO'ya çevir
- [x] **3.3** `AIGeneratorJob.GenerateTasksAsync` güncelle:
  - Her kullanıcı için 3 `DailyTask` kaydı oluştur (UserId, Category, EstimatedMinutes ile)
  - Aynı gün için mükerrer üretimi engelle (idempotent kontrol)
- [x] **3.4** AI endpoint'i (`GET /api/ai/suggestions`) doğrudan JSON Array döndürecek şekilde güncelle

---

### FAZ 4 — ReminderJob Aktivasyonu & Push Notification
> **Hedef:** Seçilen görevin zamanı geldiğinde gerçek push notification gönder.

- [x] **4.1** `ReminderJob`'daki hardcoded `"TEST_TOKEN"`'ı kaldır; kullanıcının `DeviceToken` tablosundan gerçek token'ı çek
- [x] **4.2** `Program.cs`'deki ReminderJob recurring job kaydını aktif hale getir (yorum satırından çıkar)
- [x] **4.3** Görev seçildiğinde o görev için otomatik bir `Reminder` kaydı oluştur (veya doğrudan `TaskSelection` üzerinden bildirim gönder)
- [x] **4.4** Bildirim içeriğini zenginleştir: görev başlığı, süre, motivasyon mesajı
- [ ] **4.5** `NotificationService`'deki eski FCM v1 legacy API'yi `FirebaseService` (Admin SDK) üzerinden çalışacak şekilde birleştir *(hâlâ iki ayrı servis mevcut)*

---

### FAZ 5 — Flutter: Veri Modelleri & State Management Altyapısı
> **Hedef:** Tüm ekranların üzerinde çalışacağı modeller ve state yönetim katmanını kur.

- [x] **5.1** Flutter modelleri oluştur:
  - `User` (id, name, job, age, focusArea)
  - `DailyTask` / `TaskSuggestion` (id, title, description, category, estimatedMinutes, isSelected, isCompleted)
  - `TaskSelection` (id, taskId, selectedAt, completedAt, status)
- [x] **5.2** `pubspec.yaml`'a `provider` (veya tercih edilen state management) paketini ekle
- [x] **5.3** Provider/ChangeNotifier sınıfları oluştur:
  - `UserProvider` — kullanıcı profili, backend sync
  - `TaskProvider` — günlük görevler, seçim, tamamlama
  - `StatsProvider` — istatistik verileri
- [x] **5.4** `ApiService`'e yeni endpoint çağrılarını ekle:
  - `syncUser()`, `fetchSuggestions()`, `selectTask()`, `completeTask()`, `fetchHistory()`, `fetchStats()`
- [x] **5.5** `main.dart`'ta `MultiProvider` ile provider'ları sar

---

### FAZ 6 — Flutter: Onboarding Akışı Yenileme
> **Hedef:** Kullanıcıyı tanıyarak kişiselleştirilmiş deneyim sun.

- [x] **6.1** `LoginScreen`'i çok adımlı onboarding'e dönüştür:
  - **Adım 1:** Hoş geldin + İsim girişi
  - **Adım 2:** Yaş + Meslek
  - **Adım 3:** "Gelişim Odak Alanı" seçim ekranı (görsel ikonlarla grid)
    - 🏃‍♂️ Sağlık & Fitness
    - 💼 Kariyer & Üretkenlik
    - 🧠 Zihinsel Gelişim
    - 📚 Öğrenme & Beceri
    - 🧘 Mindfulness & Stres
    - 💰 Finansal Okuryazarlık
- [x] **6.2** Onboarding tamamlandığında backend'e `POST /api/users/sync` çağrısı yap
- [x] **6.3** Kullanıcı bilgilerini hem `SharedPreferences`'a hem `UserProvider`'a kaydet
- [x] **6.4** İlk kullanım kontrolü: `SharedPreferences`'ta user yoksa → Onboarding, varsa → Home

---

### FAZ 7 — Flutter: Task Discovery Ekranı (Görev Seçimi — "Aha!" Anı)
> **Hedef:** AI'ın ürettiği 3 görev kartını sunarak kullanıcıya otonomi hissi ver.

- [x] **7.1** `TaskDiscoveryScreen` oluştur:
  - Üst başlık: "Bugün senin için hazırladık ✨"
  - 3 adet `TaskCard` widget'ı (swipeable veya scrollable)
  - Her kartta:
    - Kategori ikonu + renk kodu
    - Görev Başlığı (bold)
    - Kısa Açıklama (2-3 satır)
    - ⏱ Tahmini Süre badge'i
    - "Seç ve Başla" butonu
- [x] **7.2** Kart seçildiğinde `POST /api/dailytasks/{id}/select` çağrısı
- [x] **7.3** Seçim sonrası Home Screen'e yönlendir
- [x] **7.4** Görev önerileri yüklenmemişse veya yeni gün başlamışsa `GET /api/ai/suggestions` tetikle
- [x] **7.5** Yükleme durumu için shimmer/skeleton animasyonu

---

### FAZ 8 — Flutter: Home Screen (Aktif Görev Paneli)
> **Hedef:** Kullanıcının aktif görevini her açılışta görüp tamamlayabildiği ana ekran.

- [ ] **8.1** `HomeScreen`'i yeniden tasarla:
  - **Üst alan:** Selamlama ("Günaydın, {isim}! 👋") + tarih ✅
  - **Ana kart:** Seçilen aktif görevin detayı (başlık, açıklama, kategori, süre) ✅
  - **Geri sayım timer:** `estimatedMinutes * 60` saniye sayaç ✅
  - **"Tamamladım" butonu** — tıklandığında:
    - `POST /api/dailytasks/{id}/complete` çağrısı ✅
    - Konfeti animasyonu (confetti package) ❌ *`confetti` paketi pubspec'e eklenmedi*
    - Tebrik mesajı ✅
  - **Alt alan:** Günlük progress bar (tamamlanan / toplam) ✅
- [x] **8.2** Henüz görev seçilmemişse → Task Discovery'e yönlendir
- [x] **8.3** Gün içinde görev tamamlandıysa → "Harika iş! Yarın yeni görevler seni bekliyor" durumu
- [x] **8.4** Pull-to-refresh ile güncel veri çekme

---

### FAZ 9 — Flutter: Journey / Stats Ekranı (Gelişim Geçmişi)
> **Hedef:** Kullanıcının geçmiş performansını görselleştirerek motivasyon sağla.

- [ ] **9.1** `JourneyScreen` oluştur:
  - **Takvim görünümü:** Tamamlanan günler işaretli (streak/seri desteği) ❌ *`table_calendar` paketi yok, takvim widget'ı implement edilmedi*
  - **Liste görünümü:** Geçmiş görevler tarih sıralı ✅
  - Takvim/liste arasında toggle ✅ *(görünüm toggle'ı mevcut)*
- [ ] **9.2** Kategori bazlı istatistik grafikleri:
  - Pasta grafik veya bar chart (fl_chart paketi) ❌ *`fl_chart` paketi pubspec'e **eklenmedi**; özel canvas ile `dart:ui` kullanılıyor*
  - Kariyer: X görev, Sağlık: Y görev vb. ✅ *(custom canvas chart ile)*
- [x] **9.3** Toplam tamamlama sayısı, en uzun seri, bu haftaki performans gibi özet kartlar
- [x] **9.4** `GET /api/dailytasks/history` ve `GET /api/dailytasks/stats` entegrasyonu

---

### FAZ 10 — Flutter: Reminder & Settings Ekranı (Ayarlar)
> **Hedef:** Kullanıcının bildirim ve profil tercihlerini yönetebileceği ekran.

- [x] **10.1** `SettingsScreen` oluştur:
  - **Bildirim Zamanlayıcı:** Günlük görev hatırlatma saati seçimi (TimePicker)
  - **Profil Düzenleme:** Ad, Yaş, Meslek, Odak Alanı güncelleme
  - Değişiklikler kaydedildiğinde `POST /api/users/sync` çağrısı
- [x] **10.2** Bildirim açma/kapama toggle'ı *(UI var, ancak persist edilmiyor — bkz. eksik iş)*
- [x] **10.3** Seçilen hatırlatma saatini backend'e kaydet (Reminder veya User preferences)
- [x] **10.4** Hakkında / Versiyon bilgisi

---

### FAZ 11 — Flutter: Navigasyon & Genel UX
> **Hedef:** Tüm ekranları bir arada tutan navigasyon yapısını kur.

- [x] **11.1** Bottom Navigation Bar ekle:
  - 🏠 Home (Aktif Görev)
  - 🔍 Discover (Görev Seçimi)
  - 📊 Journey (İstatistik)
  - ⚙️ Settings (Ayarlar)
- [ ] **11.2** `MaterialApp`'e named routes tanımla *(hâlâ `MaterialPageRoute` ile doğrudan navigasyon kullanılıyor)*
- [x] **11.3** Uygulama teması (ThemeData) — tutarlı renk paleti, tipografi, kart stilleri (`app_theme.dart`)
- [x] **11.4** Splash screen + ilk yükleme akışı (auth check → onboarding / home)
- [ ] **11.5** Hata durumları için genel error widget'ları
- [ ] **11.6** `AddReminderScreen`'i `MainShell`'e bağla *(orphaned — hiçbir yoldan erişilemiyor)*

---

### FAZ 12 — Entegrasyon Testleri & Son Dokunuşlar
> **Hedef:** Uçtan uca akışların doğru çalıştığından emin ol.

- [ ] **12.1** Backend integration testleri: AI endpoint, Task CRUD, User sync
- [ ] **12.2** Flutter widget testleri: Onboarding akışı, Task Discovery, Home Screen
- [ ] **12.3** `confetti`, `fl_chart` ve `table_calendar` paketlerini pubspec'e ekle *(shimmer zaten mevcut değil — özel animasyon kullanılıyor)*
- [ ] **12.4** Uçtan uca test: Onboarding → AI suggestion → Task select → Complete → Stats görüntüleme
- [x] **12.5** README.md güncellemesi: Yeni mimari, kurulum adımları, ekran görüntüleri
- [ ] **12.6** Settings ekranındaki bildirim/dark-mode toggle'larını persist et (SharedPreferences)
- [ ] **12.7** `sendTokenToServer` null userId sorununu düzelt — token kaydı kullanıcı giriş sonrasına taşı

---

## 🔄 Bağımlılık Grafiği

```
FAZ 1 (Entity Modeli)
  └──→ FAZ 2 (API Endpoint'leri)
        ├──→ FAZ 3 (AI Prompt Revizyonu)
        │     └──→ FAZ 4 (ReminderJob Aktivasyonu)
        └──→ FAZ 5 (Flutter State & Model)
              ├──→ FAZ 6 (Onboarding)
              ├──→ FAZ 7 (Task Discovery)
              ├──→ FAZ 8 (Home Screen)
              ├──→ FAZ 9 (Journey / Stats)
              └──→ FAZ 10 (Settings)
                    └──→ FAZ 11 (Navigasyon & UX)
                          └──→ FAZ 12 (Test & Polish)
```

**Paralel çalışılabilir:**
- FAZ 1–4 (Backend) ↔ FAZ 5 (Flutter modeller & state) aynı anda başlayabilir (mock data ile)
- FAZ 7, 8, 9, 10 birbirinden bağımsız geliştirilebilir (FAZ 5 tamamlandıktan sonra)

---

## 📦 Eklenecek Flutter Paketleri

| Paket | Amaç | Durum |
|-------|------|-------|
| `provider` | State management | ✅ Eklendi |
| `google_fonts` | Tipografi | ✅ Eklendi |
| `shared_preferences` | Yerel veri saklama | ✅ Eklendi |
| `device_info_plus` | Cihaz ID alımı (FCM token kayıt) | ✅ Eklendi |
| `firebase_core` + `firebase_messaging` | Push notification | ✅ Eklendi |
| `flutter_local_notifications` | Yerel bildirim (kullanılmıyor) | ✅ Eklendi ama unused |
| `intl` | Tarih formatlama | ✅ Eklendi |
| `fl_chart` | İstatistik grafikleri | ❌ Eklenmedi |
| `confetti` | Görev tamamlama kutlama animasyonu | ❌ Eklenmedi |
| `table_calendar` | Takvim görünümü (Journey) | ❌ Eklenmedi |
| `shimmer` | Yükleme placeholder animasyonları | ❌ Eklenmedi |
| `smooth_page_indicator` | Onboarding adım göstergesi | ❌ Eklenmedi |

---

## 📦 Eklenecek Backend NuGet Paketleri

| Paket | Amaç |
|-------|------|
| — | Mevcut paketler yeterli (OpenAI, Hangfire, EF Core, Firebase Admin) |

---

## 📝 Notlar

- **CORS:** `AllowAll` politikası development için uygun, production'da kısıtlanmalı.
- **NotificationService vs FirebaseService:** `NotificationService` eski HTTP-based FCM API (`"YOUR_SERVER_KEY"` hardcoded) kullanıyor — dead code. `FirebaseService` Admin SDK kullanıyor ve `ReminderJob` tarafından doğru şekilde kullanılıyor. FAZ 4.5'te `NotificationService` kaldırılmalı.
- **Flutter notification_service.dart:** `lib/services/notification_service.dart` mevcut ama `main.dart` veya hiçbir provider'dan çağrılmıyor — dead code.
- **DeviceToken null userId:** `main.dart`'taki `sendTokenToServer` fonksiyonu `userId: null` gönderiyor. `ReminderJob` device token'ı kullanıcıya göre sorgulayacağından push notification çalışmaz. Token kaydı, kullanıcı `SharedPreferences`'tan yüklendikten sonra yapılmalı.
- **AddReminderScreen orphaned:** `MainShell` veya herhangi bir ekran bu ekrana navigate etmiyor. FAZ 11.6'da MainShell'e entegre edilmeli.
- **Namespace typo:** `DailyTasksController` ve `DeviceTokenController` dosyalarında `GrowtTracker.API.Controllers` namespace'i yazılmış (`GrowthTracker` yerine `GrowtTracker`).
- **AI Prompt dili:** OpenAI prompt'u Türkçe görev üretiyor (`gpt-4o`). Dil tercihi gelecekte eklenebilir.
- **baseUrl hardcoded:** Flutter'da `http://localhost:5058/api` olarak sabit; fiziksel cihazda veya prod'da çalışmaz. Ortama göre konfigüre edilmeli.
- **IOpenAIService yok:** `OpenAIService` direkt injection ile kullanılıyor; test edilebilirlik için interface eklenebilir.
