from flask import Flask, render_template, request, jsonify
import tensorflow as tf
import cv2
import numpy as np
from keras.models import load_model
import os
from werkzeug.utils import secure_filename
import base64
from PIL import Image
import io

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
app.config['UPLOAD_FOLDER'] = 'uploads'

if not os.path.exists('uploads'):
    os.makedirs('uploads')

try:
    import tensorflow as tf
    from tensorflow.keras.models import load_model
    from tensorflow.keras.layers import InputLayer
    
    # Create a comprehensive custom InputLayer class
    class CompatibleInputLayer(InputLayer):
        def __init__(self, input_shape=None, batch_shape=None, data_format=None, dtype=None, ragged=None, sparse=None, **kwargs):
            # Convert batch_shape to input_shape if needed
            if batch_shape is not None:
                input_shape = batch_shape[1:] if len(batch_shape) > 1 else None
            
            # Only pass supported parameters to parent class
            super().__init__(input_shape=input_shape, **kwargs)
    
    # Set up custom objects for compatibility
    custom_objects = {
        'InputLayer': CompatibleInputLayer
    }
    
    model = load_model('models/horsev2.h5', custom_objects=custom_objects, compile=False)
    # Recompile the model to ensure it works with current TensorFlow version
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")
    try:
        # Alternative loading method - try loading without custom objects first
        model = load_model('models/horsev2.h5', compile=False)
        model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
        print("Model loaded with simple method!")
    except Exception as e2:
        print(f"Simple loading failed: {e2}")
        try:
            # Last resort - try with minimal custom objects
            import tensorflow.keras.layers as layers
            
            def minimal_input_layer(**kwargs):
                # Only keep essential parameters
                essential_params = {}
                if 'input_shape' in kwargs:
                    essential_params['input_shape'] = kwargs['input_shape']
                elif 'batch_shape' in kwargs:
                    batch_shape = kwargs['batch_shape']
                    if batch_shape and len(batch_shape) > 1:
                        essential_params['input_shape'] = batch_shape[1:]
                
                if 'name' in kwargs:
                    essential_params['name'] = kwargs['name']
                
                return layers.InputLayer(**essential_params)
            
            custom_objects = {
                'InputLayer': minimal_input_layer
            }
            
            model = load_model('models/horsev2.h5', custom_objects=custom_objects, compile=False)
            model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
            print("Model loaded with minimal custom objects!")
        except Exception as e3:
            print(f"All loading methods failed: {e3}")
            model = None

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def preprocess_image(image_path):
    """Preprocess image for model prediction"""
    try:
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError("Could not read image")
        
        resize = tf.image.resize(img, (256, 256))
        normalized = resize / 255.0
        batch_img = np.expand_dims(normalized, 0)
        
        return batch_img
    except Exception as e:
        print(f"Error preprocessing image: {e}")
        return None

def predict_horse(image_path):
    if model is None:
        return {"error": "Model not loaded", "prediction": None, "confidence": 0}
    
    processed_img = preprocess_image(image_path)
    if processed_img is None:
        return {"error": "Could not process image", "prediction": None, "confidence": 0}
    
    try:
        prediction = model.predict(processed_img)
        confidence = float(prediction[0][0])
        
        if confidence > 0.5:
            result = "not a horse"
            emoji = "❌🐎"
        else:
            result = "horse detected!"
            emoji = "✅🐎"
            
        return {
            "prediction": result,
            "confidence": confidence,
            "emoji": emoji,
            "confidence_percent": round(abs(confidence - 0.5) * 200, 2)
        }
    except Exception as e:
        return {"error": f"Prediction failed: {e}", "prediction": None, "confidence": 0}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'})
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'})
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        result = predict_horse(filepath)
        
        try:
            with open(filepath, "rb") as img_file:
                img_base64 = base64.b64encode(img_file.read()).decode('utf-8')
            result['image'] = f"data:image/jpeg;base64,{img_base64}"
        except:
            result['image'] = None
        
        try:
            os.remove(filepath)
        except:
            pass
            
        return jsonify(result)
    
    return jsonify({'error': 'Invalid file type'})

if __name__ == '__main__':
    import os
    if os.environ.get('FLASK_ENV') == 'production':
        app.run(host='0.0.0.0', port=5000)
    else:
        app.run(debug=True, host='0.0.0.0', port=5000)