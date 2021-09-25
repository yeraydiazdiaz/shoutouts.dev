.PHONY: prod-devserver mac-release release server

prod-server:
	cd apps/shoutouts_web/assets && npm run deploy
	MIX_ENV=prod mix phx.digest
	MIX_ENV=prod mix phx.server

mac-release:
	MIX_ENV=prod mix distillery.release

release:
	docker-compose -f docker/docker-compose.yml build
	docker-compose -f docker/docker-compose.yml run app /opt/build/docker/build.sh

# Invokes the Phoenix dev server with a name and a shell
server:
	iex --sname phx -S mix phx.server
