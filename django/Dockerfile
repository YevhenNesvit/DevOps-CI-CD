# Базовий образ з Python
FROM python:3.11-slim

# Робоча директорія в контейнері
WORKDIR /app

# Встановлюємо залежності
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо все, що в django/, у /app
COPY . /app

# Даємо право на виконання entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Запускаємо через entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]