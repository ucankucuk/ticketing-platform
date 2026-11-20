# ADR-0006: Helm + Kustomize ile manifest paketleme

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Kubernetes manifestlerinin nasıl paketleneceği ve ortamlar arası farkların nasıl yönetileceği seçilmeli. CNCF anketinde Helm en çok tercih edilen paket yöneticisi.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Helm + Kustomize | Ortak chart + ortam overlay'leri; iki aracı da öğrenme | İki aracın birlikte kullanımı karmaşıklık ekler |
| Yalnız Helm | Tek araç, en yaygın | Ortam farkları values dosyalarında dağılır |
| Yalnız Kustomize | Şablonsuz saf YAML | Servisler arası tekrar artar |

## Karar

Servisler için ortak bir Helm chart, ortam farkları Kustomize overlay'leri ile yönetilir.

## Sonuçlar

Argo CD her ikisini de doğal olarak işleyebilir.
