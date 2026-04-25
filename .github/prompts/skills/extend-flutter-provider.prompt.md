---
agent: agent
description: Mevcut bir Flutter Provider'a yeni state alanı, getter ve API çağrısı ekler.
---

# Flutter Provider'ı Genişlet

Mevcut bir Provider'a yeni özellik eklemek için aşağıdaki adımları uygula.

## Girdi
- **Hangi Provider?** (`UserProvider`, `TaskProvider`, `StatsProvider`, veya yeni?)
- **Ne ekleniyor?** (yeni state alanı / yeni API çağrısı / yeni hesaplanan getter)
- **API endpoint var mı?** Varsa hangi HTTP metodu ve route?

## Adımlar

### 1. Mevcut Provider'ı Oku
İlgili `growth_tracker/lib/providers/<x>_provider.dart` dosyasını oku. Mevcut state alanlarını ve metodları anla, çakışma yaratma.

### 2. State Alanı Ekle
Private alan + public getter şablonu:

```dart
// private alan — mevcut alanların yanına ekle
List<YourModel> _newItems = [];
bool _isNewLoading = false;  // zaten _isLoading varsa ayrı field gerekmeyebilir

// getter'lar — mevcut getter'ların yanına ekle
List<YourModel> get newItems => _newItems;
bool get isNewLoading => _isNewLoading;
```

**Kural:** Mevcut `_isLoading` genel yükleme için kullanılıyorsa, yeni işlem için ayrı `_isXLoading` ekle.

### 3. API Metodu Ekle
```dart
Future<void> loadNewItems(String userId) async {
  _isNewLoading = true;
  _error = null;
  notifyListeners();

  try {
    _newItems = await _api.<apiMethod>(userId);
  } catch (e) {
    _error = e.toString();
  } finally {
    _isNewLoading = false;
    notifyListeners();
  }
}
```

**Kurallar:**
- Her async metodun başında `notifyListeners()` çağır (loading state için)
- try/catch/finally zorunlu
- Hata `_error`'a yaz, throw etme
- Sonunda `notifyListeners()` çağır

### 4. ApiService Metodu Ekle (gerekiyorsa)
`growth_tracker/lib/services/api_service.dart` dosyasını oku. Yeni HTTP çağrısını ekle:

```dart
Future<List<YourModel>> fetch<X>(String userId) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/<endpoint>?userId=$userId'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => YourModel.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load <X>: ${response.statusCode}');
  }
}
```

### 5. Model Sınıfı Ekle (gerekiyorsa)
`growth_tracker/lib/models/<x>.dart` yok ise oluştur:

```dart
class YourModel {
  final int id;
  final String title;

  const YourModel({required this.id, required this.title});

  factory YourModel.fromJson(Map<String, dynamic> json) => YourModel(
        id: json['id'] as int,
        title: json['title'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
```

### 6. Ekranlarda Kullanım
Değiştirilmesi gereken ekranlar varsa belirt:
```dart
// build içinde:
final items = context.watch<XProvider>().newItems;

// callback içinde:
context.read<XProvider>().loadNewItems(userId);
```

## Kontrol Listesi
- [ ] State alanı private olarak eklendi (`_camelCase`)
- [ ] Public getter eklendi
- [ ] Async metod try/catch/finally ile sarıldı
- [ ] `notifyListeners()` hem başında (loading) hem sonunda çağrılıyor
- [ ] ApiService metodu eklendi (gerekiyorsa)
- [ ] Model sınıfı fromJson/toJson ile oluşturuldu (gerekiyorsa)
- [ ] Ekranlarda `context.watch` / `context.read` doğru kullanılıyor
