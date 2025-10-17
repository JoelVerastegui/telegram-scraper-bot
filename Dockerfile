# ----------------------------------------------------------------------
# Etapa 1: Builder - Se utiliza una imagen que contiene el SDK de Dart
# para obtener las dependencias y compilar el código.
# ----------------------------------------------------------------------
FROM dart:3.6-sdk AS builder

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# 1. Copia los archivos de definición del proyecto (pubspec.yaml y pubspec.lock)
# Esto permite aprovechar la caché de Docker si no cambian.
COPY pubspec.* .

# 2. Obtiene las dependencias
RUN dart pub get

# 3. Copia el resto del código fuente del proyecto.
# Esto es CRUCIAL para que el compilador tenga acceso a los archivos de origen
# (bin/main.dart, lib/*) y a la configuración de paquetes (.dart_tool/).
COPY . .

# 4. Forzamos una revalidación de las dependencias en modo offline.
# Esto corrige problemas de resolución de rutas que a menudo ocurren dentro
# del entorno Docker antes de la compilación AOT.
RUN dart pub get --offline

# 5. Compila la aplicación de Dart a un ejecutable nativo (AOT compilation)
# Esto crea un binario independiente y de alto rendimiento para Linux.
# El ejecutable compilado se llamará 'scraper-bot'.
RUN dart compile exe bin/web_scraping_telegram_bot.dart -o /app/scraper-bot

# ----------------------------------------------------------------------
# Etapa 2: Final - Se utiliza una imagen base ligera para el resultado
# ----------------------------------------------------------------------

# Utilizamos 'debian:bookworm-slim' ya que la imagen 'scratch' podría ser
# demasiado mínima para ejecutar binarios Dart AOT sin librerías.
FROM debian:bookworm-slim

# Instala librerías mínimas necesarias para ejecutar el binario AOT de Dart
# y para que funcione la conexión a red (como el scraping y Telegram).
RUN apt-get update && \
    apt-get install -y --no-install-recommends libssl-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Establece el directorio de trabajo
WORKDIR /app

# Copia el ejecutable compilado de la etapa 'builder'
COPY --from=builder /app/scraper-bot /app/

# Define el punto de entrada para el contenedor
# El ejecutable 'scraper-bot' será lo que corra al iniciar el contenedor.
ENTRYPOINT ["/app/scraper-bot"]

# **********************************************************************
# INSTRUCCIONES DE USO:
# 1. Asegúrate de que el código fuente de tu app esté en el mismo directorio que este Dockerfile.
# 2. Reemplaza 'bin/main.dart' con la ruta correcta a tu archivo principal si es necesario.
# 3. Construye la imagen (ejecuta en el directorio del proyecto):
#    docker build -t nombre-de-la-imagen .
# **********************************************************************
