#!/usr/bin/env bash

echo "Downloading patched hex"
mix archive.install --force github 650health/hex branch latest
echo "Patched hex installed"

# Install rebar3 manually.
# It is needed to fetch erlang dependencies. Mix will
# fail to download it.
echo "Downloading rebar3"
curl -L -o rebar3 https://s3.amazonaws.com/rebar3/rebar3
chmod +x ./rebar3
./rebar3 local install
export PATH=/root/.cache/rebar3/bin:$PATH
mix local.rebar rebar3 $(which rebar3)
echo "Rebar installed"

echo "Updating bashrc with env vars"
echo 'export HEX_CACERTS_PATH="$CODEX_PROXY_CERT"' >>/root/.bashrc
echo 'export PATH=/root/.cache/rebar3/bin:$PATH' >>/root/.bashrc
echo "Done"
