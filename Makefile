.PHONY: docker-cleanup
docker-cleanup:
	docker container kill $(shell docker container ls -qa) || true
	docker container rm $(shell docker container ls -qa) || true
	docker volume rm $(shell docker volume ls -q) || true
	docker network prune -f
	docker system prune -f
	docker rmi $(shell docker images -q)
