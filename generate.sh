#!/usr/bin/env bash
#
# Regenerates api/client.gen.go from the live OpenAPI spec.
#
# Requirements (both pinned: a different version may produce a gratuitously
# different client):
#   go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.7.1
#   pip install openapi-downgrade==1.0.1

set -eo pipefail

OPENAPI_SPEC_RAW="$(mktemp)"
OPENAPI_SPEC="$(mktemp)"
OPENAPI_SPEC_30="$(mktemp)"

curl -fsS https://rest.cleura.cloud/apidoc.json > "${OPENAPI_SPEC_RAW}"

# The published spec is OpenAPI 3.1 and contains empty `"required": []` arrays.
# They are legal there (JSON Schema 2020-12) but invalid in 3.0, where `required`
# has minItems 1 — so they have to go before the downgrade. This is line-oriented
# text surgery on someone else's document: report the match count so a spec
# reformat (or an upstream fix) is visible instead of silently changing the input.
empty_required="$(grep -c -E '"required":[[:space:]]*\[[[:space:]]*\]' "${OPENAPI_SPEC_RAW}" || true)"
if [ "${empty_required}" -eq 0 ]; then
	echo "NOTE: no empty \"required\": [] arrays found. Either the API stopped emitting them" >&2
	echo "      (drop this step) or the spec's formatting changed (fix the pattern)." >&2
fi
sed -r '/^.*required": \[\].*$/d' "${OPENAPI_SPEC_RAW}" > "${OPENAPI_SPEC}"

openapi_downgrade "${OPENAPI_SPEC}" "${OPENAPI_SPEC_30}"

oapi-codegen -config client-oapi-config.yaml "${OPENAPI_SPEC_30}"
echo "Generated api/client.gen.go (stripped ${empty_required} empty \"required\" arrays)"
