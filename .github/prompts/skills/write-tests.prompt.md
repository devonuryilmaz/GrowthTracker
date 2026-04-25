---
agent: agent
description: Flutter widget testi veya .NET xUnit unit testi yazar — projenin mevcut yapısına uygun.
---

# Test Yaz

Aşağıdaki adımları uygula. Test türünü ve hedef kodu belirt.

## Girdi
- **Test türü:** Flutter widget testi mi, .NET unit testi mi?
- **Test edilecek şey:** Hangi widget/ekran veya hangi Service/method?
- **Test senaryoları:** Hangi durumları kapsamalı? (happy path, edge case, hata durumu)

---

## Flutter Widget Testi

### Test Dosyası
`growth_tracker/test/<screen_or_widget>_test.dart`

### Şablon
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:growth_tracker/providers/<x>_provider.dart';
import 'package:growth_tracker/screens/<x>_screen.dart';

void main() {
  group('<XScreen> widget tests', () {
    Widget buildTestWidget({required <X>Provider provider}) {
      return ChangeNotifierProvider<XProvider>.value(
        value: provider,
        child: const MaterialApp(home: <X>Screen()),
      );
    }

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      final provider = <X>Provider();
      // provider'ı yüklenme durumuna al (mock veya gerçek)

      await tester.pumpWidget(buildTestWidget(provider: provider));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error is set', (tester) async {
      // ...
    });

    testWidgets('renders content when data is loaded', (tester) async {
      // ...
    });
  });
}
```

### Kurallar
- Provider'ı doğrudan mock'lamak yerine test constructor veya `..` ile state ayarla
- Her test bağımsız (state sızmaması için ayrı provider instance'ı)
- `tester.pump()` sync, `tester.pumpAndSettle()` animasyonlu durumlar için

---

## .NET Unit Testi

### Test Projesi (yoksa)
```bash
cd GrowthTracker
dotnet new xunit -n GrowthTracker.Tests
dotnet sln add GrowthTracker.Tests/GrowthTracker.Tests.csproj
cd GrowthTracker.Tests
dotnet add reference ../GrowthTracker.API.csproj
dotnet add package Moq
dotnet add package Microsoft.EntityFrameworkCore.InMemory
```

### Test Dosyası
`GrowthTracker.Tests/<X>ServiceTests.cs`

### Şablon
```csharp
using GrowthTracker.API.Data;
using GrowthTracker.API.Entity;
using GrowthTracker.API.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace GrowthTracker.Tests;

public class <X>ServiceTests
{
    private AppDbContext CreateInMemoryContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task <MethodName>_<Scenario>_<ExpectedResult>()
    {
        // Arrange
        using var context = CreateInMemoryContext();
        var logger = new Mock<ILogger<<X>Service>>();
        var service = new <X>Service(context, logger.Object);

        // seed data
        context.<Entity>s.Add(new <Entity> { /* ... */ });
        await context.SaveChangesAsync();

        // Act
        var result = await service.<MethodName>(<params>);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(expected, result.<Property>);
    }
}
```

### Naming Convention
Test metod adı: `MethodName_Scenario_ExpectedBehavior`  
Ör: `GetUserById_ValidId_ReturnsUser`, `CreateReminder_PastDate_ThrowsException`

### Kurallar
- In-memory DB her test için fresh (`Guid.NewGuid()` ile unique isim)
- Mock sadece dış bağımlılıklar için (Logger, external HTTP, Firebase)
- `AppDbContext` in-memory ile gerçek test et, mock'lama
- Arrange / Act / Assert blokları boş satırla ayrılsın

## Kontrol Listesi
- [ ] Her senaryo ayrı `[Fact]` veya `[Theory]`
- [ ] Test metod adı `Method_Scenario_Expected` formatında
- [ ] Arrange/Act/Assert bölümleri açık
- [ ] State testler arası sızmıyor (izole context/provider)
- [ ] En az 1 happy path + 1 edge/hata senaryosu
