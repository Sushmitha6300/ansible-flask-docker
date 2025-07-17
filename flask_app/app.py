from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, this is Shravani’s custom Flask app running in Docker via Ansible!"
