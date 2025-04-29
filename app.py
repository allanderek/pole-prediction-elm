import bottle
import os

app = bottle.Bottle()

# Define index.html content as a string literal
INDEX_HTML = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pole Prediction</title>
    <link rel="icon" type="image/svg" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48' viewBox='0 0 16 16'><text x='0' y='14'>🏎️</text></svg>"/>
    <link rel="stylesheet" href="/static/styles.css">
    <script src="/static/main.js"></script>
</head>
<body>
    <h1>Pole Prediction</h1>
    <script> var app = Elm.Main.init({}); </script>
</body>
</html>"""

# Serve static files from the 'static' directory
@app.route('/static/<filepath:path>')
def serve_static(filepath):
    return bottle.static_file(filepath, root='./static')

# Serve index.html for '/' and any path starting with '/app'
@app.route('/')
@app.route('/app')
@app.route('/app/<path:path>')
def serve_index(path=None):
    return INDEX_HTML

# API routes
@app.route('/api/hello/<name>', method='GET')
def hello(name):
    return {'message': f'Hello, {name}!'}

@app.route('/api/resource', method=['GET', 'POST'])
def resource():
    if bottle.request.method == 'GET':
        return {'status': 'ok', 'data': 'Resource data'}
    elif bottle.request.method == 'POST':
        data = bottle.request.json
        return {'status': 'created', 'data': data}

# Make sure the static directory exists
os.makedirs('./static', exist_ok=True)

if __name__ == '__main__':
    bottle.run(app, host='localhost', port=3003, debug=True)
