RED = \033[0;31m
NC = \033[0m # No Color
GREEN = \033[0;32m

define log_section
	@printf "\n${GREEN}--> $(1)${NC}\n\n"
endef

venv-setup:
	$(call log_section, Create virtual environment...)
	rm -rf .venv
	python3.11 -m venv .venv
	.venv/bin/python -m pip install --upgrade pip
	# .venv/bin/python -m pip install -r ./requirements.txt --quiet


test-workflow:
	$(call log_section, Setup the infra to chat on data, and test response...)
	rm -rf variables.env
	pwsh ./scripts/1_setup.ps1
	sleep 2
	pwsh ./scripts/2_upload_files.ps1
	sleep 2
	pwsh ./scripts/3_create_deployments.ps1
	sleep 2
	pwsh ./scripts/4_invoke_oai.ps1


# Commit local branch changes
branch=$(shell git symbolic-ref --short HEAD)
now=$(shell date '+%F_%H:%M:%S' )
git-push:
	git add . && git commit -m "Changes as of $(now)" && git push -u origin $(branch)


# Force remote to align with the local branch
force-remote:
	git push origin main --force

git-pull:
	git pull origin $(branch)
