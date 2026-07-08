# cleura-client-go

Go client for the [Cleura Cloud REST API](https://rest.cleura.cloud/), generated from the
OpenAPI specification with [oapi-codegen](https://github.com/oapi-codegen/oapi-codegen).

Used by the [Cleura CLI](https://github.com/cleura/cleura-cli) and (eventually) the
[Cleura Terraform provider](https://github.com/cleura/terraform-provider-cleura).

## Versioning

While on v0.x, no API-stability promise is made. In particular, the `api`
package is generated from the live OpenAPI specification and is regenerated as
the API evolves: new operations extend the generated interfaces (which breaks
code that *implements* them, e.g. mocks — embed the interface instead), and
regeneration may rename generated identifiers. Surface-affecting regenerations
bump the minor version; the hand-written `cleura` package only grows —
additions, no changes.

## Installing

```sh
go get github.com/cleura/cleura-client-go@latest
```

## Usage

```go
import (
    "github.com/cleura/cleura-client-go/api"
    "github.com/cleura/cleura-client-go/cleura"
)

url, _ := cleura.DefaultAPIURL("public") // or your private cloud API URL

client, err := cleura.NewClientWithCredentials(url, username, token)
if err != nil {
    return err
}

resp, err := client.IdentityGetCurrentUserWithResponse(ctx)
if err != nil {
    return err
}
if resp.JSON200 == nil {
    var apiErr api.FrameworkHttpErrorResponse
    if json.Unmarshal(resp.Body, &apiErr) == nil && apiErr.Error.Message != "" {
        return fmt.Errorf("%s (HTTP %d)", apiErr.Error.Message, resp.StatusCode())
    }
    return fmt.Errorf("unexpected response %s", resp.Status())
}
fmt.Println(resp.JSON200.Name)
```

`cleura.NewClient(url)` creates an unauthenticated client for endpoints that do not
require credentials, such as token creation (`POST /auth/v2/tokens`). Both
constructors accept additional `api.ClientOption`s (custom `http.Client`, request
editors, ...).

Note: for endpoints whose responses are not JSON (e.g. the admin kubeconfig,
which the server returns with a non-matching Content-Type), read `resp.Body`
directly instead of the typed response field.

## Packages

- `api` — generated client and models (`api/client.gen.go`). Do not edit by hand.
- `cleura` — thin hand-written wrapper: authentication header injection and API URL defaults.

## Regenerating the client

`./generate.sh` fetches the current spec from the live API and regenerates the client:

```sh
go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.7.1  # pinned; see generate.sh
pip install openapi-downgrade
./generate.sh
```

The generated surface is limited to the API tags listed in `client-oapi-config.yaml`
(`include-tags`). Add tags there as more of the API is needed and rerun `./generate.sh`.
