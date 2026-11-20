# ADR-0019: Argo CD kurulumu ve GitOps yapısı

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

ADR-0007 ile CD aracı olarak Argo CD seçildi. Kurulum yöntemi, platform bileşenlerinin Argo CD'de nasıl tanımlanacağı, senkronizasyon politikası ve Argo CD'nin kendi yönetimi belirlenmeli.

## Seçenekler

| Konu | Seçilen | Alternatif |
| --- | --- | --- |
| Kurulum | Resmi, sürüme sabitlenmiş manifest + Kustomize | Topluluk Helm chart'ı (argo/argo-cd) |
| Uygulama yapısı | App-of-apps | ApplicationSet |
| Senkronizasyon | Otomatik, self-heal ve prune açık | Manuel sync |
| Argo CD'nin yönetimi | Kendini Git'ten yönetir (self-management) | Yalnız betikle kurulur |

## Karar

- Argo CD v3.6.2, resmi `install.yaml` manifesti üzerine Kustomize ile kurulur (`deploy/argocd/bootstrap`).
- `root` adlı kök Application, `deploy/argocd/apps` altındaki her Application'ı uygular.
- Tüm Application'larda otomatik senkronizasyon, self-heal ve prune açıktır.
- Argo CD kendi kurulumunu da `apps/argocd.yaml` üzerinden yönetir; sürüm yükseltmesi bir PR ile yapılır.
- İlk kurulumu `scripts/cluster-up.sh` yapar (bootstrap); bundan sonra cluster'daki her değişiklik Git üzerinden gelir.

## Sonuçlar

- Cluster'da elle yapılan değişiklikler Argo CD tarafından geri alınır; değişiklikler yalnızca Git'ten yapılır.
- Argo CD, `main` branch'ini izler; PR birleşmeden cluster değişmez.
- Cilium, ağ olmadan Argo CD çalışamayacağı için betikle kurulmaya devam eder; ileride Argo CD'ye devredilmesi değerlendirilebilir.
