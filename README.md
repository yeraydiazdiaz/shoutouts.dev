# shoutouts.dev

[shoutouts.dev](https://shoutouts.dev) is a plaform for OSS users to post public
messages of gratitude for projects they love.

shoutouts.dev is currently in **beta**, please use this repo to raise any issues
with the site and discuss possible improvements.

## Contributing

PRs are welcome. I am fairly new to Elixir and Phoenix, so any advice on best
practices is greatly appreciated.

### Dev setup

First you'll need to install:

- Elixir 1.11.2, probably best using your package manager.
- Node 13, [`nvm`](https://github.com/nvm-sh/nvm) works best.
- PostgreSQL 12, use Docker, your package manager, or [Postgres app](https://postgresapp.com/).

Then:

1. `cd apps/shoutouts_web/static/
2. `npm i`
3. Back in the root dir, `mix deps.get`
4. `mix ecto.create`
5. `mix ecto.migrate`
6. `mix run apps/shoutouts/priv/repo/seeds.exs`
7. `mix phx.server` or `mix test`

### Configuration

The configuration is split in several files in the `config` directory.

- `config.exs` includes common configuration options.
- `dev.exs` options for development
- `test.exs` for testing
- `prod.exs` for production
- `prod.secret.exs` is effectively empty as we use environment variables
via [Vapor](https://github.com/keathley/vapor), check each sub-app's
`application.exs` for more details.

### Frontend

We use Tailwind CSS and some vanilla JS in conjunction with Phoenix's JS library.

The webpack configuration is modified from the default Phoenix includes:

- PostCSS is added for Tailwind CSS.
- PurgeCSS is included to reduce the CSS payload to include only those styles
used in the templates. **This means changing classes in the web inspector may
not work as expected as the new class may have been purged**. If you're
experiencing issues when making CSS changes it's worth commenting out the
PurgeCSS section until you're done.
- Fonts found in CSS are copied directly to /fonts/ and SVGs are included as
URLs so they will need to be used in CSS classes.

### Dependencies

As an umbrella project each app has its own mix.exs where dependencies are set.
Generally all web-specific dependencies should go on the web app's mix.exs
while "backend" deps on the base's.

### Releases

We use [Distillery](https://hexdocs.pm/distillery/home.html) to produce release
artifacts. These are built an Ubuntu 20.04 Docker image and a build bash
script that produces release tarballs executable in any Ubuntu 20.04 system.

### Provider integrations

#### GitHub

A developer app must be created to allow users to sign in with:

- "Request user authorizaion (OAuth) during installation"
- Callback URL `http://<DOMAIN>/auth/github/`
- "Webhook" disabled

The app's ID, client ID and client secret need to be set in their respective
configuration variables.

Additionally a GitHub API token is used to retrieve public information about
the user.
