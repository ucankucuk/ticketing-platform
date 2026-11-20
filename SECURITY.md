# Güvenlik

Bu bir öğrenme ve portföy projesidir; üretimde kullanılmak için tasarlanmamıştır.

Bir güvenlik açığı bulursan lütfen herkese açık bir issue açma. Bunun yerine GitHub'ın **Security → Report a vulnerability** (özel güvenlik bildirimi) özelliğini kullan.

## Repo kuralları

- Parola, token, özel anahtar veya kubeconfig asla commit edilmez.
- Gizli bilgiler için seçilecek yöntem (secret yönetimi) bir ADR ile belirlenir.
- GitHub secret scanning ve push protection açıktır; bir sır yanlışlıkla gönderilirse hemen iptal edilip yenilenir.
