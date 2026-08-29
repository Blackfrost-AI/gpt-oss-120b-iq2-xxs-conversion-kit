.PHONY: setup assets source preflight convert validate check

setup:
	./scripts/setup_toolchain.sh

assets:
	./scripts/download_assets.sh

source:
	./scripts/prepare_source.sh

preflight:
	./scripts/preflight.sh

convert:
	./scripts/convert.sh

validate:
	./scripts/validate.sh

check:
	./scripts/check_repo.sh
