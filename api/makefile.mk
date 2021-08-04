api_DEPS := base
api_SHELL := sh

api.test::
	docker run monorepo/api npm run test
