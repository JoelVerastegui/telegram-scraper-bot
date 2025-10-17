## 🤖 Scraper Bot: Búsqueda de elementos HTML con notificaciones de Telegram

Este proyecto es una aplicación de línea de comandos (CLI) escrita en Dart que realiza web scraping en una URL definida para obtener los elementos HTML a consultar y envía notificaciones a un chat de Telegram con los datos solicitados.

### 🚀 Requisitos

Para ejecutar esta aplicación, necesitas:

1. __Dart SDK (Solo para ejecución local):__ Versión 3.6.0 o superior.

2. __Docker:__ Para la ejecución mediante contenedores.

3. __Token de Telegram:__ Un token de bot obtenido de BotFather.

### ⚙️ Configuración de Credenciales

__Esta aplicación lee el Token directamente de las variables de entorno.__

Asegúrate de configurar las siguientes variables con tus valores:

| Variable    | Uso |
| -------- | ------- |
| TELEGRAM_BOT_TOKEN  | El token de autorización de tu bot de Telegram.    |


### 💻 Ejecución Local

1. Instala las dependencias
```
dart pub get
```

2. Ejecuta el siguiente comando reemplazando el texto __ingresa_tu_token__ por el token del bot de Telegram.
```
dart run -DTELEGRAM_BOT_TOKEN=ingresa_tu_token
```


### 🐳 Ejecución con Docker

El Dockerfile compila el código en un ejecutable binario y espera recibir el Token como variable de entorno al momento de la ejecución.

1. Obtén la imagen
```
docker pull joelverastegui/telegram-scraper-bot:latest
```

2. Ejecuta el contenedor

Ejecuta el siguiente comando reemplazando el texto __ingresa_tu_token__ por el token del bot de Telegram.
```
docker run -d --name scraping-bot -e TELEGRAM_BOT_TOKEN="ingresa_tu_token" joelverastegui/telegram-scraper-bot:latest
```

| Parámetro    | Significado |
| -------- | ------- |
| -d  | Ejecuta el contenedor en segundo plano e imprime el ID del contenedor |
| --name  | Asigna un nombre al contenedor |
| -e  | Establece variables de entorno |

### 🛠️ Contribución

Si deseas contribuir al código fuente, clona este repositorio, asegúrate de tener el Dart SDK instalado y sigue los pasos de Ejecución Local para probar tus cambios.