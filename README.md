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

Note: a few endpoints do not return JSON, and for those you read `resp.Body`
directly instead of a typed response field. The only such case in the generated
surface today is the shoot SSH private key
(`GardenerGetShootSshPrivateKey`, `text/plain`) — gate on
`resp.StatusCode()/100 == 2` and treat an empty body as an error.

The admin kubeconfig used to belong in that list and no longer does: prefer
`GardenerCreateShootAdminKubeConfigV3WithResponse`, whose `JSON201` is a typed
`api.GardenerAdminKubeConfig{ExpiresAt, Kubeconfig}`. The v2 operation
(`GardenerCreateShootAdminKubeConfigWithResponse`) is deprecated upstream and
still needs the raw-body treatment, because the server sends it with a
Content-Type that does not match the body.

## Packages

- `api` — generated client and models (`api/client.gen.go`). Do not edit by hand.
- `cleura` — thin hand-written wrapper: authentication header injection and API URL defaults.

## Regenerating the client

`./generate.sh` fetches the current spec from the live API and regenerates the client:

```sh
go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.7.1  # pinned; see generate.sh
pip install openapi-downgrade==1.0.1                                          # pinned
./generate.sh
```

The generated surface is limited to the API tags listed in `client-oapi-config.yaml`
(`include-tags`). Add tags there as more of the API is needed and rerun `./generate.sh`.

Because the spec is fetched live, a regeneration also picks up whatever else has
changed upstream — review the diff, not just the operations you came for. The
script prints how many empty `"required": []` arrays it stripped from the spec
(they are legal in OpenAPI 3.1 but invalid in the 3.0 document the generator
needs); a count of zero means either the API fixed it or the pattern stopped
matching, and both deserve a look.
