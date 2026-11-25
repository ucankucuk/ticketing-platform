# Ticketing Platform

Global, mikroservis tabanlı bir bilet satış platformu. Çok ülke ve şehirde, koltuklu etkinlikler için ani satış (flash sale) yükünü kaldıracak şekilde tasarlanıyor ve Kubernetes üzerinde çalışıyor.

Bu proje bir öğrenme ve portföy projesidir: amaç mikroservis patternlerini, mesajlaşmayı, cache'i ve Kubernetes'i gerekçeleriyle, üretime yakın bir ortamda uygulamaktır. Her kritik karar [ADR](docs/adr/) olarak kayıtlıdır.

## Durum

Faz 0, platform: repo, CI ve yerel Kubernetes ortamı kuruluyor. Henüz uygulama servisi yok.

## Mimari özet

- **Müşteri tarafı:** Web önyüz, Edge (API Gateway + BFF), etkinlik bazlı dinamik bekleme odaları (Waiting Room), Catalog, Seat Inventory, Booking (saga), Payment, Ticketing, Notification, Search
- **Arka ofis:** Arka ofis web uygulaması, Admin BFF, Organizer, Access Control (çevrimdışı check-in), Reporting, Audit
- **Altyapı:** Kimlik sağlayıcı (OIDC, üç ayrı kimlik alanı), mesaj aracısı, iş kuyruğu, dağıtık cache, arama deposu, gözlemlenebilirlik
- **Dağıtım:** Bölgesel hücre (cell) modeli; her bölge aynı topolojiye sahip bir Kubernetes cluster'ı

Somut teknolojiler fazlar ilerledikçe ADR ile seçilir. Ayrıntılı tasarım: [docs/architecture](docs/architecture/README.md).

## Teknoloji tabanı

| Alan | Seçim |
| --- | --- |
| Dil | Java 25 |
| Framework | Spring Boot 4 (en güncel kararlı sürüm) |
| Build | Maven (çok modüllü) |
| Yerel Kubernetes | kind (çok düğümlü) |
| Manifest paketleme | Helm + Kustomize |
| CI / CD | GitHub Actions + Argo CD (GitOps) |

## Repo yapısı

```
services/      Backend mikroservisleri (her biri bir Maven modülü)
libs/          Ortak kütüphaneler (mesaj zarfı, hata modeli, para/zaman tipleri)
frontends/     Müşteri web önyüzü, arka ofis uygulaması, check-in uygulaması
deploy/
  helm/        Servisler için ortak Helm chart'ları
  kustomize/   Ortam overlay'leri (local, ...)
  argocd/      Argo CD Application tanımları
platform/      Cluster ve platform bileşenleri (yerel kind ortamı dahil)
scripts/       Yardımcı betikler
docs/
  adr/         Mimari karar kayıtları
  architecture/ Mimari doküman
```

## Yerel ortamı başlatma

Gereksinimler: Docker, [kind](https://kind.sigs.k8s.io/), kubectl, Helm, Java 25, Maven 3.9+

```bash
./scripts/cluster-up.sh      # 1 control-plane + 3 worker düğümlü kind cluster
./scripts/cluster-down.sh    # cluster'ı siler
mvn verify                   # build ve testler
```

Servisler `https://<servis>.ticketing.localhost` adresinden yayınlanır. Sertifika cluster içindeki yerel CA tarafından imzalanır; tarayıcı ve `curl` uyarı vermesin diye CA sertifikasını alıp sisteme güvenilir olarak ekleyebilirsiniz:

```bash
kubectl -n cert-manager get secret local-ca-root -o jsonpath='{.data.ca\.crt}' | base64 -d > local-ca.crt
```

## Lisans

[Apache License 2.0](LICENSE)
