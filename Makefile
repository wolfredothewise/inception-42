# ==========================================
# DIRECTOR DE ORQUESTA MINIMALISTA
# ==========================================

NAME		= inception
DATA_PATH	= /home/vhedo-ga/data
COMPOSE		= docker compose -f ./srcs/docker-compose.yml

all:
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@$(COMPOSE) up --build -d

down:
	@$(COMPOSE) down

clean: down
	@$(COMPOSE) down -v

fclean: clean
	@sudo rm -rf $(DATA_PATH)/mariadb
	@sudo rm -rf $(DATA_PATH)/wordpress
	@docker system prune -af --volumes

re: fclean all

.PHONY: all down clean fclean re
