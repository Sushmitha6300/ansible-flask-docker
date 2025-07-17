from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, this is Sushmitha’s custom Flask app running in Docker via Ansible!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
