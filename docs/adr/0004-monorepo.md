# ADR-0004: Monorepo

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Servisler, önyüzler ve dağıtım manifestlerinin repo organizasyonu seçilmeli.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Monorepo | Atomik değişiklik, kolay gezinme ve sergileme | CI'da etkilenen modülü seçmek gerekir |
| Monorepo + ayrı GitOps reposu | Kod ve ortam durumu ayrılır | İki repo yönetimi |
| Polyrepo | Ekip bağımsızlığını simüle eder | Tek kişi için ağır |

## Karar

Tek bir monorepo kullanılır: `services/`, `libs/`, `frontends/`, `deploy/`, `platform/`.

## Sonuçlar

Argo CD aynı repodaki `deploy/` dizinini izler. Gerekirse ileride ortam manifestleri ayrı repoya taşınabilir.
