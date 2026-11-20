# Katkı ve çalışma şekli

## Branch ve commit

- `main` korumalıdır; değişiklikler pull request ile gelir ve CI'ın geçmesi gerekir.
- Branch adları: `feat/...`, `fix/...`, `chore/...`, `docs/...`
- Commit mesajları [Conventional Commits](https://www.conventionalcommits.org/) biçimindedir: `feat(catalog): etkinlik listeleme ucu`

## Mimari kararlar

Mimariyi etkileyen her karar `docs/adr/` altında yeni bir ADR olarak eklenir. Şablon: [docs/adr/0000-template.md](docs/adr/0000-template.md).

## Yerel kontrol

```bash
mvn verify
./scripts/cluster-up.sh
```
