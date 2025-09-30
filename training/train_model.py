#!/usr/bin/env python3
"""
Custom Sign Language Model Training
Uses TensorFlow Lite Model Maker for efficient mobile model training
"""

import os
import tensorflow as tf
import tensorflow_lite_model_maker as mm
from tensorflow_lite_model_maker import image_classifier
import json
import argparse
from pathlib import Path

class SignLanguageModelTrainer:
    def __init__(self, data_dir, model_output_dir, model_name='sign_classifier'):
        self.data_dir = Path(data_dir)
        self.model_output_dir = Path(model_output_dir)
        self.model_name = model_name
        
        # Create output directory
        self.model_output_dir.mkdir(exist_ok=True)
        
        # Training configuration
        self.config = {
            'epochs': 10,
            'batch_size': 32,
            'learning_rate': 0.001,
            'model_spec': mm.image_classifier.model_spec.mobilenet_v2_spec,
            'validation_split': 0.0,  # We already have separate validation data
            'shuffle': True
        }
    
    def load_data(self):
        """Load training and validation data"""
        print("📂 Loading training data...")
        
        train_dir = self.data_dir / 'train'
        val_dir = self.data_dir / 'val'
        
        if not train_dir.exists():
            raise FileNotFoundError(f"Training directory not found: {train_dir}")
        if not val_dir.exists():
            raise FileNotFoundError(f"Validation directory not found: {val_dir}")
        
        # Load data using Model Maker
        train_data = image_classifier.DataLoader.from_folder(
            str(train_dir),
            shuffle=self.config['shuffle']
        )
        
        val_data = image_classifier.DataLoader.from_folder(
            str(val_dir),
            shuffle=False
        )
        
        print(f"✅ Training samples: {len(train_data)}")
        print(f"✅ Validation samples: {len(val_data)}")
        print(f"🏷️ Classes: {train_data.index_to_label}")
        
        return train_data, val_data
    
    def create_model(self, train_data, val_data):
        """Create and train the model"""
        print("🧠 Creating and training model...")
        
        # Create model
        model = image_classifier.create(
            train_data,
            model_spec=self.config['model_spec'],
            validation_data=val_data,
            epochs=self.config['epochs'],
            batch_size=self.config['batch_size'],
            learning_rate=self.config['learning_rate'],
            shuffle=self.config['shuffle']
        )
        
        return model
    
    def evaluate_model(self, model, test_data=None):
        """Evaluate model performance"""
        print("📊 Evaluating model performance...")
        
        if test_data is None:
            # Load test data if not provided
            test_dir = self.data_dir / 'test'
            if test_dir.exists():
                test_data = image_classifier.DataLoader.from_folder(str(test_dir))
            else:
                print("⚠️ No test data found, skipping evaluation")
                return None
        
        # Evaluate
        evaluation = model.evaluate(test_data)
        print(f"✅ Test Accuracy: {evaluation:.4f}")
        
        return evaluation
    
    def export_model(self, model):
        """Export model to TensorFlow Lite format"""
        print("📦 Exporting model to TensorFlow Lite...")
        
        # Export to TensorFlow Lite
        tflite_path = self.model_output_dir / f"{self.model_name}.tflite"
        model.export(
            export_dir=str(self.model_output_dir),
            tflite_filename=f"{self.model_name}.tflite",
            quantization_config=mm.image_classifier.QuantizationConfig.for_float16()
        )
        
        # Export labels
        labels_path = self.model_output_dir / 'labels.txt'
        with open(labels_path, 'w') as f:
            for label in model.model_spec.config.class_names or model.index_to_label:
                f.write(f"{label}\n")
        
        print(f"✅ Model exported: {tflite_path}")
        print(f"✅ Labels exported: {labels_path}")
        
        return str(tflite_path), str(labels_path)
    
    def save_training_info(self, model, evaluation=None):
        """Save training metadata"""
        info = {
            'model_name': self.model_name,
            'training_config': self.config,
            'classes': list(model.index_to_label) if hasattr(model, 'index_to_label') else [],
            'model_spec': str(self.config['model_spec']),
            'export_timestamp': tf.timestamp().numpy().item()
        }
        
        if evaluation:
            info['test_accuracy'] = float(evaluation)
            info['test_loss'] = float(evaluation)
        
        info_path = self.model_output_dir / f"{self.model_name}_info.json"
        with open(info_path, 'w') as f:
            json.dump(info, f, indent=2)
        
        print(f"📄 Training info saved: {info_path}")
    
    def train(self):
        """Main training pipeline"""
        print("🚀 Starting model training pipeline...")
        
        try:
            # Load data
            train_data, val_data = self.load_data()
            
            # Create and train model
            model = self.create_model(train_data, val_data)
            
            # Evaluate model
            evaluation = self.evaluate_model(model)
            
            # Export model
            tflite_path, labels_path = self.export_model(model)
            
            # Save training info
            self.save_training_info(model, evaluation)
            
            print("✅ Model training completed successfully!")
            print(f"📁 Model files saved in: {self.model_output_dir}")
            
            return True, tflite_path, labels_path
            
        except Exception as e:
            print(f"❌ Training failed: {e}")
            return False, None, None

def main():
    parser = argparse.ArgumentParser(description='Train custom sign language recognition model')
    parser.add_argument('--data', required=True, help='Path to preprocessed data directory')
    parser.add_argument('--output', required=True, help='Output directory for trained model')
    parser.add_argument('--name', default='sign_classifier', help='Model name')
    parser.add_argument('--epochs', type=int, default=10, help='Training epochs')
    parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
    
    args = parser.parse_args()
    
    trainer = SignLanguageModelTrainer(args.data, args.output, args.name)
    trainer.config['epochs'] = args.epochs
    trainer.config['batch_size'] = args.batch_size
    
    success, model_path, labels_path = trainer.train()
    
    if success:
        print(f"\n🎉 Training completed successfully!")
        print(f"📦 TFLite Model: {model_path}")
        print(f"🏷️ Labels: {labels_path}")
        print("\n📱 Copy these files to your Flutter app's assets/models/ directory")
    else:
        print("\n❌ Training failed!")
        exit(1)

if __name__ == '__main__':
    main()