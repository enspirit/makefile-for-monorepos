api_DEPS := base
api_SHELL := sh

api.tests.unit::
	@docker run monorepo/api npm run test:unit

api.tests.integration::
	@docker run monorepo/api npm run test:integration
