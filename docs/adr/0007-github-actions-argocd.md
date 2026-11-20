# ADR-0007: GitHub Actions (CI) + Argo CD (CD)

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Repo GitHub'da; build/test ve Kubernetes'e dağıtım yöntemi seçilmeli. CNCF anketine göre en yaygın CI/CD platformları GitHub Actions ve Argo; Argo CD GitOps'ta çoğunluk konumunda.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| GitHub Actions + Argo CD | Pull-based GitOps, arayüzlü, sektör standardı | Cluster içinde ek bileşen |
| GitHub Actions + Flux | Hafif, CLI odaklı | Arayüz yok |
| Yalnız GitHub Actions (push) | Basit | GitOps öğrenilmez, CI'a cluster yetkisi gerekir |

## Karar

CI GitHub Actions ile build, test ve imaj üretir. Argo CD repodaki `deploy/` manifestlerini cluster'a çeker.

## Sonuçlar

CI'ın cluster kimlik bilgisine ihtiyacı olmaz; cluster durumu Git'teki tanımla eşitlenir.
