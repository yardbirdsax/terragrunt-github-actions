.phony: template
template:
	if [[ -z "$$GIT_TAG" ]]; then \
		GIT_TAG=$$(git rev-parse HEAD); \
		export GIT_TAG; \
	fi && \
	docker run -e GIT_TAG -v $$PWD:/workspace hairyhenderson/gomplate:stable -f /workspace/action.yml.tpl -o /workspace/action.yml