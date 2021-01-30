#!/usr/bin/env bash

set -e

cd /opt/build

APP_NAME=shoutouts_umbrella
MIX_FILE=apps/shoutouts/mix.exs
APP_VSN="$(grep 'version:' $MIX_FILE | cut -d '"' -f2)"
echo "Building artifact $APP_NAME $APP_VSN"

mkdir -p /opt/app/rel/artifacts

export MIX_ENV=prod

# Fetch deps and compile
mix deps.clean appsignal  # workaround for https://github.com/appsignal/appsignal-elixir/issues/254
mix deps.get
# Maybe run an explicit clean to remove any build artifacts from the host?
mix compile

# Build static assets
cd /opt/build/apps/shoutouts_web/assets
npm install
npm run deploy
# Build manifest file
cd /opt/build/apps/shoutouts_web/
mix phx.digest

# Build the release
cd /opt/build/
mix distillery.release
# Copy tarball to output
cp "_build/prod/rel/$APP_NAME/releases/$APP_VSN/$APP_NAME.tar.gz" /opt/build/rel/artifacts/"$APP_NAME-$APP_VSN.tar.gz"
echo "Artifact built on rel/artifacts/$APP_NAME-$APP_VSN.tar.gz"

exit 0
