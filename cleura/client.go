// Package cleura wraps the generated api client with authentication header
// injection and API URL defaults for the Cleura Cloud REST API.
package cleura

import (
	"context"
	"net/http"

	api "github.com/cleura/cleura-client-go/api"
)

// Client talks to the Cleura Cloud REST API. It embeds the generated
// api.ClientWithResponses, so every generated *WithResponse method is
// available on it.
type Client struct {
	*api.ClientWithResponses
}

// NewClient creates a wrapped API client without credentials. Only endpoints
// that do not require authentication (e.g. token creation) can be called.
// Additional options (custom http.Client, request editors, ...) are applied
// in order.
func NewClient(url string, opts ...api.ClientOption) (*Client, error) {
	cleura, err := api.NewClientWithResponses(url, opts...)
	if err != nil {
		return nil, err
	}

	return &Client{
		cleura,
	}, nil
}

// NewClientWithCredentials creates a wrapped API client that authenticates
// every request with the given username and token. Additional options are
// applied after the authentication editor.
func NewClientWithCredentials(url, username, token string, opts ...api.ClientOption) (*Client, error) {
	options := append([]api.ClientOption{
		api.WithRequestEditorFn(func(ctx context.Context, req *http.Request) error {
			req.Header.Set("X-AUTH-LOGIN", username)
			req.Header.Set("X-AUTH-TOKEN", token)
			return nil
		}),
	}, opts...)

	return NewClient(url, options...)
}
