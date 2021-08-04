api_DEPS := base

api.test::
	docker run monorepo/api npm run test
