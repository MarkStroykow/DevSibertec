#!/bin/bash

# !1. В случае возникновения ошибок скрипт должен завершиться с выводом сообщения о соответствующей ошибке.
function handle_error {
    echo "Ошибка: $1"
    exit 1
}

#1. убедиться, что докер в системе запущен и работает.
if ! docker info > /dev/null 2>&1; then
    handle_error "Docker не запущен или не работает"
fi

#2. убедиться в работоспособности интернета и доступности репозитория с исходным кодом.
if ! ping -c 1 github.com > /dev/null 2>&1; then
    handle_error "Нет доступа к интернету"
fi

# !!!!!!!!!!!!!!!!!!!docker-compose, git installed и git work + docker на всякий
if ! docker info > /dev/null 2>&1; then
	handler_error "Docker не запущен или не работает"
fi

if ! command -v git > /dev/null 2>&1; then
    handler_error "Git не установлен"
fi

if ! git --version > /dev/null 2>&1; then
    handler_error "Git работает не корректно"
fi

if ! command -v docker-compose > /dev/null 2>&1; then
    handler_error "Docker-compose не установлен"
fi

if ! git ls-remote https://github.com/Lissy93/dashy.git > /dev/null 2>&1; then
    handle_error "Репозиторий недоступен"
fi

git clone https://github.com/Lissy93/dashy.git || handle_error "Не удалось клонировать репозиторий"

#3. создать dockerfile.
# !2. при сборке docker-image использовать базовый образ alpine версии 3.17.
cat <<EOF > Dockerfile || handle_error "Не удалось создать Dockerfile"
FROM alpine:3.17
RUN apk add --no-cache nodejs npm
WORKDIR /app
COPY dashy .
RUN npm install
RUN npm run build
ENV PORT=80
EXPOSE 80
CMD ["npm", "start"]
EOF

#4. собрать из исходников docker-image приложения dashy.
if ! docker build -t dashy-app .; then
    handle_error "Не удалось собрать Docker image"
fi

#5. выгрузить полученный docker-image в файл.
if ! docker save -o dashy-app.tar dashy-app; then
    handle_error "Не удалось выгрузить Docker image в файл"
fi


#7. загрузить docker-image из файла.
if ! docker load -i dashy-app.tar; then
    handle_error "Не удалось загрузить Docker image из файла"
fi

#8. создать файл docker-compose.yml
# !3. приложение должно быть доступно только локально, на порту 8080.
cat <<EOF > docker-compose.yml || handle_error "Не удалось создать файл docker-compose.yml"
version: '3'
services:
  dashy:
    image: dashy-app
    ports:
      - "8080:80"
    restart: always
EOF

#9. при помощи docker-compose запустить контейнер с приложением.
if ! docker-compose up -d; then
    handle_error "Не удалось запустить контейнер с помощью docker-compose"
fi

sleep 10

#10. проверить работоспособность приложения.
if ! curl -s http://localhost:8080 > /dev/null; then
    handle_error "Приложение недоступно на порту 8080"
fi

echo "Приложение успешно запущено и доступно на порту 8080"

sleep 10

#6. удалить в докер все контейнеры и очистить локальный registry.
#rm -rf dashy
#docker container stop $(docker container ls -aq) 2>/dev/null || true
#docker container rm $(docker container ls -aq) 2>/dev/null || true
#docker image rm $(docker image ls -aq) 2>/dev/null || true
echo "Приложение успешно запущено и доступно на порту 8080"
