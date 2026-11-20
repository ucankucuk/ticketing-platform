# ADR-0014: Secret yönetimi için External Secrets Operator ve OpenBao

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Repo herkese açık; düz Kubernetes Secret dosyaları commit'lenemez. GitOps akışı (Argo CD) bozulmamalı.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| External Secrets Operator + OpenBao | Git'te yalnız referans; değer cluster içi kasada; kurumsal modele en yakın; rotasyon kolay | Kasanın kurulumu ve işletimi |
| Sealed Secrets | En basit saf GitOps | Şifreli değer cluster anahtarına bağlı; rotasyon zahmetli |
| SOPS + age | Dosya seviyesinde şifreleme, Helm ile uyumlu | Argo CD için eklenti gerekir |

## Karar

External Secrets Operator kullanılır; secret deposu cluster içinde çalışan OpenBao'dur (HashiCorp Vault'un Linux Foundation altındaki açık kaynak fork'u).

## Sonuçlar

Uygulamalar yalnızca Kubernetes Secret görür; kasa değişirse yalnız SecretStore tanımı değişir.
