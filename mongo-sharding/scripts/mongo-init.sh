#!/bin/bash

#
# 1. Инициализация config-сервера
#
echo "Инициализация config-сервера..."
docker-compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  });
EOF
echo "Config-сервер инициализирован."

#
# 2. Инициализация первого шарда
#
echo "Инициализация первого шарда..."
docker-compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1:27018" }
    ]
});
EOF
echo "Shard1 инициализирован."

#
# 3. Инициализация второго шарда
#
echo "Инициализация второго шарда..."
docker-compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({
    _id : "shard2",
    members: [
      { _id : 0, host : "shard2:27019" }
    ]
});
EOF
echo "Shard2 инициализирован."

#
# 4. Подключение шардов к роутеру и заполнение данными
#
echo "Подключение шардов к роутеру и заполнение данными..."
docker-compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb
for (var i = 0; i < 1000; i++) {
    db.helloDoc.insertOne({ age: i, name: "ly" + i })
}
db.helloDoc.countDocuments()
EOF
echo "Шардирование завершено и данные добавлены."

read -p "Нажмите Enter для выхода..."