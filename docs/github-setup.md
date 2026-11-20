# GitHub kurulum rehberi

Bu adımlar repo ilk kez GitHub'a yüklenirken bir kez yapılır.

## 1. Repoyu oluştur ve yükle

GitHub CLI ile (lisans dosyasını GitHub'ın resmi Apache-2.0 şablonundan ekler):

```bash
gh repo create ticketing-platform --public --license apache-2.0 \
  --description "Global, mikroservis tabanlı bilet satış platformu (Java 25, Spring Boot 4, Kubernetes)"
git clone https://github.com/<KULLANICI_ADI>/ticketing-platform.git
# Bu iskeletin içeriğini klonlanan klasöre kopyala, sonra:
git add .
git commit -m "chore: proje iskeleti, ADR'ler ve CI"
git push origin main
```

Web arayüzünden oluşturuyorsan: **New repository → Public → Add a license: Apache License 2.0**.

## 2. Güvenlik ayarları (Settings → Code security)

- **Dependency graph** ve **Dependabot alerts**: açık
- **Dependabot security updates**: açık
- **Secret scanning** ve **Push protection**: açık (açık repolarda ücretsiz)
- **Code scanning**: `.github/workflows/codeql.yml` zaten tanımlı; ilk çalışmadan sonra sonuçlar Security sekmesinde görünür
- **Private vulnerability reporting**: açık (SECURITY.md buna yönlendiriyor)

## 3. `main` branch kuralı (Settings → Rules → Rulesets)

Yeni bir branch ruleset oluştur, hedef: `main`:

- Restrict deletions
- Block force pushes
- Require a pull request before merging (tek kişi olduğun için onay sayısı 0 olabilir)
- Require status checks to pass: `Build ve test (Java 25)`, `Kind cluster smoke testi`
- Require linear history

## 4. Actions ayarları (Settings → Actions → General)

- Workflow permissions: **Read repository contents** (varsayılan en az yetki)
- "Allow GitHub Actions to create and approve pull requests": kapalı

## 5. Repo görünümü

- About bölümüne topic'ler: `java`, `spring-boot`, `kubernetes`, `microservices`, `gitops`, `argocd`, `helm`, `kind`, `event-driven`
- README'deki mimari özeti ve ADR bağlantısı ziyaretçinin ilk göreceği yerdir

## Not: Actions sürüm sabitleme

Workflow'larda action'lar şimdilik sürüm etiketiyle (`@v5`) kullanılıyor. Tedarik zinciri güvenliği için ileride commit SHA ile sabitlenecek; Dependabot SHA'ları da güncelleyebilir.
