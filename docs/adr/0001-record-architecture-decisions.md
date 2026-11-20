# ADR-0001: Mimari kararları ADR olarak kaydetmek

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Proje bir öğrenme ve portföy projesi; kararların gerekçesi en az kodun kendisi kadar değerli.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| ADR (Markdown, repoda) | Kodla birlikte versiyonlanır, PR ile incelenir | Disiplin ister |
| Wiki / harici doküman | Kolay düzenlenir | Koddan kopar, eskir |

## Karar

Her kritik karar `docs/adr/` altında numaralı bir ADR olur. Her ADR seçenekleri, artı/eksileri ve sektördeki kullanımı içerir.

## Sonuçlar

Karar geçmişi izlenebilir; bir karar değişirse eski ADR silinmez, yerini alan ADR'ye bağlanır.
