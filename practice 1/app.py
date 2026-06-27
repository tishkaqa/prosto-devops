#!/usr/bin/env python3
"""
Простое Flask-приложение для демонстрации работы Docker
"""
import os
from datetime import datetime
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Получаем переменные окружения
APP_VERSION = os.getenv('APP_VERSION', '1.0.0')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
STUDENT_NAME = os.getenv('STUDENT_NAME', 'Student')

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Practice - Success!</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 600px;
            text-align: center;
        }
        .success-icon {
            font-size: 80px;
            margin-bottom: 20px;
        }
        h1 {
            color: #2d3748;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #4a5568;
            font-size: 18px;
            margin-bottom: 30px;
        }
        .info-block {
            background: #f7fafc;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 15px 0;
            text-align: left;
            border-radius: 5px;
        }
        .info-block strong {
            color: #2d3748;
        }
        .info-block span {
            color: #667eea;
            font-weight: bold;
        }
        .footer {
            margin-top: 30px;
            color: #718096;
            font-size: 14px;
        }
        .badge {
            display: inline-block;
            padding: 5px 15px;
            background: #48bb78;
            color: white;
            border-radius: 20px;
            font-size: 12px;
            margin: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✅</div>
        <h1>Задание успешно выполнено!</h1>
        <p class="subtitle">Docker-контейнер работает корректно</p>

        <div class="info-block">
            <strong>👤 Студент:</strong> <span>{{ student_name }}</span>
        </div>

        <div class="info-block">
            <strong>🐳 Версия приложения:</strong> <span>{{ version }}</span>
        </div>

        <div class="info-block">
            <strong>🌍 Окружение:</strong> <span>{{ environment }}</span>
        </div>

        <div class="info-block">
            <strong>🕐 Время запуска:</strong> <span>{{ timestamp }}</span>
        </div>

        <div class="info-block">
            <strong>🔌 Порт:</strong> <span>8080</span>
        </div>

        <div style="margin-top: 20px;">
            <span class="badge">Docker ✓</span>
            <span class="badge">Python ✓</span>
            <span class="badge">Flask ✓</span>
        </div>

        <div class="footer">
            <p>Практическое задание по Docker</p>
            <p><small>Контейнер запущен и работает на localhost:8080</small></p>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    """Главная страница с информацией об успешном выполнении"""
    return render_template_string(
        HTML_TEMPLATE,
        student_name=STUDENT_NAME,
        version=APP_VERSION,
        environment=ENVIRONMENT,
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )

@app.route('/health')
def health():
    """Endpoint для проверки здоровья приложения"""
    return jsonify({
        'status': 'healthy',
        'message': 'Задание выполнено успешно!',
        'version': APP_VERSION,
        'environment': ENVIRONMENT,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/info')
def info():
    """Информация о приложении"""
    return jsonify({
        'student': STUDENT_NAME,
        'app_version': APP_VERSION,
        'environment': ENVIRONMENT,
        'python_version': os.sys.version,
        'port': 8080,
        'endpoints': [
            {'path': '/', 'description': 'Главная страница'},
            {'path': '/health', 'description': 'Проверка здоровья'},
            {'path': '/info', 'description': 'Информация о приложении'}
        ]
    })

if __name__ == '__main__':
    print(f"🐳 Запуск приложения версии {APP_VERSION}")
    print(f"🌍 Окружение: {ENVIRONMENT}")
    print(f"👤 Студент: {STUDENT_NAME}")
    print(f"🔌 Порт: 8080")
    print("=" * 50)

    app.run(host='0.0.0.0', port=8080, debug=False)
