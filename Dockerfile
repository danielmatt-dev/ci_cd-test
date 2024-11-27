# Usar una imagen base ligera de Python
FROM python:3.10-slim

# Definir una variable de entorno para el directorio de la aplicación
ENV APP_HOME=/app

# Crear el directorio de trabajo dentro del contenedor
RUN mkdir -p "$APP_HOME"
WORKDIR $APP_HOME

# Evitar que se generen archivos .pyc y forzar la salida sin buffer
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Crear un entorno virtual dentro del contenedor
RUN python -m venv /opt/venv

# Añadir el entorno virtual al PATH para asegurarse de que se use por defecto
ENV PATH="/opt/venv/bin:$PATH"

# Copiar el archivo de requisitos al contenedor e instalar dependencias del sistema
COPY requirements.txt .

# Instalar las dependencias del sistema necesarias para librerías como mysqlclient
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Instalar las dependencias de Python usando pip dentro del entorno virtual
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar todo el código de la aplicación al directorio de trabajo en el contenedor
COPY . .

# Ejecutar migraciones de Django al construir la imagen
RUN python manage.py makemigrations && \
    python manage.py migrate

# Exponer el puerto 9000 para el servidor de Django
EXPOSE 8000

# Configurar el script de entrada y comando para iniciar la aplicación usando el entorno virtual
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Añadir un HEALTHCHECK para monitorear la salud del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl --fail http://localhost:9000 || exit 1
