#!/usr/bin/env python3
import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import urlopen
from urllib.error import URLError

BACKEND_URL = os.getenv('BACKEND_URL', 'http://backend:5000')
APP_NAME = os.getenv('APP_NAME', 'Frontend')

class FrontendHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        # Пытаемся получить данные с backend
        try:
            with urlopen(BACKEND_URL, timeout=2) as response:
                backend_data = json.loads(response.read().decode())
                counter = backend_data.get('counter', 0)
                messages = backend_data.get('messages', [])
                backend_status = '✅ Connected'
        except URLError as e:
            counter = 0
            messages = []
            backend_status = f'❌ Error: {e}'

        html = f"""
        <html>
        <head>
            <title>{APP_NAME}</title>
            <style>
                body {{
                    font-family: Arial;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: #f0f0f0;
                }}
                .container {{
                    background: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }}
                h1 {{ color: #333; }}
                .status {{
                    padding: 10px;
                    background: #e8f5e9;
                    border-left: 4px solid #4caf50;
                    margin: 10px 0;
                }}
                .info {{ color: #666; }}
                button {{
                    padding: 10px 20px;
                    background: #2196f3;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    cursor: pointer;
                    font-size: 16px;
                    margin: 5px;
                }}
                button:hover {{ background: #1976d2; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎨 {APP_NAME}</h1>
                <div class="status">
                    <strong>Backend Status:</strong> {backend_status}<br>
                    <strong>Backend URL:</strong> {BACKEND_URL}
                </div>
                <div class="info">
                    <h2>Counter: {counter}</h2>
                    <button onclick="fetch('{BACKEND_URL}/increment').then(() => location.reload())">
                        Increment Counter
                    </button>
                </div>
                <div class="info">
                    <h3>Messages ({len(messages)}):</h3>
                    <ul>
                        {''.join(f'<li>{msg}</li>' for msg in messages)}
                    </ul>
                </div>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        print(f"[FRONTEND] {self.address_string()} - {format % args}")

if __name__ == '__main__':
    print(f"=== {APP_NAME} Service ===")
    print(f"Backend URL: {BACKEND_URL}")
    print("Starting frontend on port 8080...")

    server = HTTPServer(('0.0.0.0', 8080), FrontendHandler)
    server.serve_forever()
