################################################################################
### This plugin allows you to upgrade Makefile when we release new versions
###
### WARNING: this plugin requires curl & [jq](https://github.com/stedolan/jq)
###
### * make Makefile.upgrade checks for new versions and downloads them.
###

# Subscribe the plugin
$(eval $(call mk-plugin-subscribe) mk-manager)

# Which github repo hosts the Makefile
# You can fork us on github, override this variable in your config.mk
# and get updates from your own clone.
MK_GH_REPO := $(or ${MK_GH_REPO},${MK_GH_REPO},enspirit/makefile-for-monorepos)

# By overriding this variable to 'true' you'll get upgrades from the
# master branch rather than the latest release (use at your own risk)
MK_USE_CANARY := $(or ${MK_USE_CANARY},${MK_USE_CANARY},false)

MK_GH_CONTENTS_API := https://api.github.com/repos/$(MK_GH_REPO)/contents
MK_GH_LATEST_RELEASE := https://api.github.com/repos/$(MK_GH_REPO)/releases/latest
MK_GH_MK_MASTER_URL := https://raw.githubusercontent.com/$(MK_GH_REPO)/master/Makefile

#
# $1: name of release
# $2: url to download the Makefile
#
define upgrade-makefile
@echo "Upgrading Makefile to $1..."
@echo "Downloading $2..."
mv Makefile .Makefile.bckp && (wget -q $2 && rm .Makefile.bckp) || mv .Makefile.bckp Makefile;
@echo "Upgrade successful!"
exit 0
endef

.PHONY: Makefile.upgrade
Makefile.upgrade:
	@if [ "$(MK_USE_CANARY)" == "true" ]; then
		$(call upgrade-makefile,latest canary release,$(MK_GH_MK_MASTER_URL))
	fi
	@echo "Current version: $(MK_VERSION)"
	@local_sha=`git hash-object Makefile`
	@original_sha=`curl -s $(MK_GH_CONTENTS_API)/Makefile?ref=$(MK_VERSION) | jq -r '.sha'`
	if [ "$$local_sha" != "$$original_sha" ] && [ -z $${MK_FORCE:-} ]; then \
		>&2 echo "Your Makefile seems to have been modified compared to the original... aborting."; \
		>&2 echo "(you can force the update by running 'MK_FORCE=true make Makefile.upgrade' but you'll loose your modifications)"; \
		exit 2; \
	fi
	@latest_version=`curl -s $(MK_GH_LATEST_RELEASE) | jq -r '.tag_name'`
	@echo "Latest version: $$latest_version"
	@if [ "$(MK_VERSION)" == "$$latest_version" ]; then \
		echo "You already have the latest version."; \
		exit 0; \
	fi
	@makefile_download_url=`curl -s $(MK_GH_LATEST_RELEASE) | jq -r '.assets[] | select(.name=="Makefile") | .browser_download_url'`
	$(call upgrade-makefile,$$latest_version,$$makefile_download_url)

.PHONY: Makefile.plugins.list
Makefile.plugins.list: $(addsuffix .info,$(MK_PLUGINS))