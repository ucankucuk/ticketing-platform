# ADR-0008: Apache-2.0 lisansı ve açık repo

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Proje GitHub'da portföy olarak yayınlanacak.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Apache-2.0 | Serbest kullanım + patent maddesi; Spring ve Kubernetes'in lisansı | MIT'ten uzun |
| MIT | Kısa ve serbest | Patent maddesi yok |
| Lisanssız | Tüm haklar saklı | Kimse yasal olarak kullanamaz |

## Karar

Apache-2.0 lisansı ve ilk günden herkese açık repo.

## Sonuçlar

Açık repo nedeniyle secret yönetimi kritik; ayrı bir ADR ile ele alınacak.
