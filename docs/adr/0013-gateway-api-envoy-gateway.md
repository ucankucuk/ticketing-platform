# ADR-0013: Cluster girişi için Gateway API ve Envoy Gateway

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Dış trafiğin cluster'a girişi için bir uygulama seçilmeli. Ingress NGINX Mart 2026'da emekliye ayrıldı; Kubernetes topluluğu Gateway API'ye yönlendiriyor.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Envoy Gateway | Envoy'un resmi Gateway API uygulaması; standarda sadık, bağımsız | Ayrı bir bileşen |
| Cilium Gateway | Cilium seçildiği için ek bileşen yok | Özellik kapsamı daha dar |
| Istio Gateway | Mesh gelirse aynı araç | Tek başına giriş için ağır |
| NGINX Gateway Fabric | NGINX deneyimi olan ekipler için tanıdık | Envoy ekosistemi dışında |

## Karar

Gateway API kaynakları (GatewayClass, Gateway, HTTPRoute) ve Envoy Gateway kullanılır. Ingress API kullanılmaz.

- Envoy Gateway v1.10.0, OCI Helm chart'ıyla Argo CD üzerinden kurulur (`deploy/argocd/apps/envoy-gateway.yaml`). Gateway API CRD'leri (standart kanal) chart ile gelir.
- Cluster'da tek bir `public` Gateway vardır (`platform/gateway`, `gateway` namespace'i). `http` (80) listener'ı yalnızca HTTPS'e 301 yönlendirmesi yapar; `https` (443) listener'ında TLS sonlanır. Sertifika `*.ticketing.localhost` için cert-manager'ın `local-ca` issuer'ından gelir (ADR-0018).
- Servisler kendi namespace'lerinde HTTPRoute tanımlayıp `public` Gateway'in `https` listener'ına bağlanır. Bunun için namespace'in `ticketing.io/gateway-access: "true"` etiketini taşıması gerekir; etiketsiz namespace'lerin route'ları reddedilir.
- Yerelde LoadBalancer olmadığından Envoy'un Service'i sabit NodePort'ludur (30080/30443); kind bunları host'un `127.0.0.1:80/443` portlarına eşler.

## Sonuçlar

Uygulamaya özel annotation bağımlılığı olmaz; yönlendirme kuralları taşınabilir kalır.
