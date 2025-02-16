import os
import json
import time
import requests
from flask import Flask, request, jsonify, send_file

app = Flask(__name__)

URL = "http://127.0.0.1:8188/prompt"
OUTPUT_DIR = "/Users/esra/Desktop/ComfyUI/output"

def get_latest_images(folder, count=4):
    """Fetches the latest 'count' images from the output directory."""
    files = os.listdir(folder)
    image_files = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    image_files.sort(key=lambda x: os.path.getmtime(os.path.join(folder, x)), reverse=True)
    latest_images = [os.path.join(folder, f) for f in image_files[:count]]
    return latest_images

def start_queue(prompt_workflow):
    """Starts the queue with the provided prompt workflow."""
    p = {"prompt": prompt_workflow}
    data = json.dumps(p).encode('utf-8')
    requests.post(URL, data=data)

def generate_images(prompt_text):
    """Generates 4 images based on the input prompt."""
    with open("comfyui_image_generator.json", "r") as file_json:
        prompt = json.load(file_json)
        prompt["6"]["inputs"]["text"] = f"digital artwork of a {prompt_text}"
        prompt["5"]["inputs"]["batch_size"] = 4  # Create 4 images in one run

    start_queue(prompt)
    previous_images = get_latest_images(OUTPUT_DIR)

    while True:
        latest_images = get_latest_images(OUTPUT_DIR, count=4)
        if set(latest_images) != set(previous_images):
            return latest_images
        time.sleep(1)

@app.route("/generate", methods=["POST"])
def generate():
    """API endpoint to generate images from a given prompt."""
    data = request.get_json()
    prompt_text = data.get("prompt")

    if not prompt_text:
        return jsonify({"error": "Prompt text is required"}), 400

    image_paths = generate_images(prompt_text)

    if image_paths:
        image_urls = [f"http://127.0.0.1:5001/image/{os.path.basename(img)}" for img in image_paths]
        return jsonify({"image_urls": image_urls})
    else:
        return jsonify({"error": "Failed to generate images"}), 500

@app.route("/image/<filename>", methods=["GET"])
def get_image(filename):
    """API endpoint to retrieve an image by filename."""
    image_path = os.path.join(OUTPUT_DIR, filename)
    if os.path.exists(image_path):
        return send_file(image_path, mimetype="image/png")
    else:
        return jsonify({"error": "Image not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
