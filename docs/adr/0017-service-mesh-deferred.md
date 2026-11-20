# ADR-0017: Service mesh şimdilik kullanılmıyor

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Service mesh; mTLS, trafik yönetimi ve retry/timeout gibi davranışları uygulamadan altyapıya taşır.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Şimdilik yok | Dayanıklılık patternleri önce uygulama içinde öğrenilir; daha az karmaşıklık | Servisler arası mTLS yok |
| Istio ambient | En yaygın mesh | Baştan eklemek karmaşıklığı artırır |
| Cilium service mesh | Cilium zaten var | Istio kadar zengin değil |
| Linkerd | Hafif | Kurumsal yaygınlığı daha az |

## Karar

Service mesh şimdilik kullanılmaz. İleri bir fazda seçenekleriyle yeniden değerlendirilir.

## Sonuçlar

Retry, timeout ve circuit breaker uygulama içinde (Resilience4j) yazılır.
