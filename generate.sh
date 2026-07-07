#!/usr/bin/env bash
#
# Regenerates api/client.gen.go from the live OpenAPI spec.
#
# Requirements (the generator is pinned: a different version may produce a
# gratuitously different client):
#   go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.7.1
#   openapi_downgrade: pip install openapi-downgrade

set -eo pipefail

OPENAPI_SPEC="$(mktemp)"
OPENAPI_SPEC_30="$(mktemp)"

curl -fsS https://rest.cleura.cloud/apidoc.json | sed -r '/^.*required": \[\].*$/d' > "${OPENAPI_SPEC}"
openapi_downgrade "${OPENAPI_SPEC}" "${OPENAPI_SPEC_30}"

oapi-codegen -config client-oapi-config.yaml "${OPENAPI_SPEC_30}"
echo "Generated api/client.gen.go"
