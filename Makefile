# 快捷命令
export LAB_ROOT := $(CURDIR)
COMPOSE := docker compose --project-directory $(CURDIR) -f $(CURDIR)/compose/docker-compose.yml --env-file $(CURDIR)/.env
PROFILE ?= core

.PHONY: up down status ps logs k8s k8s-delete clean help

up:
	bash scripts/up.sh $(PROFILE)

down:
	bash scripts/down.sh $(PROFILE)

status:
	bash scripts/status.sh $(PROFILE)

ps:
	$(COMPOSE) --profile $(PROFILE) ps

logs:
	$(COMPOSE) --profile $(PROFILE) logs -f --tail=100

k8s:
	bash scripts/k8s-create.sh

k8s-delete:
	bash scripts/k8s-delete.sh

stress:
	bash scripts/stress.sh 60 http://localhost:8081

clean:
	$(COMPOSE) --profile core --profile logs --profile tracing --profile lb --profile redis --profile redis-ha --profile redis-cluster --profile db --profile mq --profile cicd --profile linux down -v

help:
	@echo "make up PROFILE=core      启动 core（可观测性）"
	@echo "make up PROFILE=redis     启动 Redis 单机"
	@echo "make up PROFILE=redis-ha  启动 Redis 主从+哨兵"
	@echo "make up PROFILE=redis-cluster  启动 Redis Cluster"
	@echo "make up PROFILE=db        启动 MySQL / PostgreSQL"
	@echo "make up PROFILE=mq        启动 Kafka / RabbitMQ"
	@echo "make up PROFILE=lb        启动 Nginx / HAProxy"
	@echo "make up PROFILE=cicd      启动 Gitea"
	@echo "make up PROFILE=linux     启动 Linux 练习容器"
	@echo "make k8s                  创建 kind 集群并部署示例"
	@echo "make clean                清理全部容器和数据卷"
