from app import routes  # Ensure routes are registered
from flask import Flask

app = Flask(__name__)

# Optional: Load environment variables or configs
app.config.from_pyfile('../config.py', silent=True)
