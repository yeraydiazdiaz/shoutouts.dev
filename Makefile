prod-devserver:
	cd apps/shoutouts_web/assets && npm run deploy
	MIX_ENV=prod mix phx.digest
	MIX_ENV=prod mix phx.server

mac-release:
	MIX_ENV=prod mix distillery.release

release:
	COOKIE="$(shell cat .dev/COOKIE)" docker-compose -f docker/docker-compose.yml build
	docker-compose -f docker/docker-compose.yml run app /opt/build/docker/build.sh

.PHONY: release
