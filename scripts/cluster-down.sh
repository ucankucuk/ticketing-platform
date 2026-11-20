#!/usr/bin/env bash
# Yerel kind cluster'ını siler.
set -euo pipefail
kind delete cluster --name ticketing-local
