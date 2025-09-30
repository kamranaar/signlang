#!/usr/bin/env python3
"""
Sign Language Data Preprocessing Pipeline
Converts exported JSON data and images into training format
"""

import json
import os
import shutil
from pathlib import Path
import cv2
import numpy as np
from sklearn.model_selection import train_test_split
import argparse

class SignLanguageDataPreprocessor:
    def __init__(self, data_json_path, output_dir, image_size=224):
        self.data_json_path = data_json_path
        self.output_dir = Path(output_dir)
        self.image_size = image_size
        self.classes = []
        
        # Create output directories
        self.output_dir.mkdir(exist_ok=True)
        (self.output_dir / 'train').mkdir(exist_ok=True)
        (self.output_dir / 'val').mkdir(exist_ok=True)
        (self.output_dir / 'test').mkdir(exist_ok=True)
        
    def load_data(self):
        """Load and parse the exported JSON data"""
        print(f"📋 Loading data from {self.data_json_path}")
        
        with open(self.data_json_path, 'r') as f:
            data = json.load(f)
        
        print(f"✅ Loaded {data['total_samples']} samples")
        print(f"📊 Found {len(data['labels'])} unique labels: {data['labels']}")
        
        return data
    
    def filter_and_balance_data(self, data, min_samples=10, max_samples=200):
        """Filter classes with sufficient samples and balance dataset"""
        print(f"🔍 Filtering classes (min: {min_samples}, max: {max_samples} samples)")
        
        stats = data['stats']
        valid_labels = [label for label, count in stats.items() 
                       if count >= min_samples]
        
        print(f"✅ Valid labels after filtering: {valid_labels}")
        
        # Filter training data
        filtered_data = []
        for item in data['data']:
            if item['label'] in valid_labels:
                filtered_data.append(item)
        
        # Balance classes
        balanced_data = []
        for label in valid_labels:
            label_samples = [item for item in filtered_data if item['label'] == label]
            
            # Limit samples per class
            if len(label_samples) > max_samples:
                np.random.seed(42)
                label_samples = np.random.choice(label_samples, max_samples, replace=False).tolist()
            
            balanced_data.extend(label_samples)
            print(f"📝 {label}: {len(label_samples)} samples")
        
        self.classes = sorted(valid_labels)
        print(f"🎯 Final dataset: {len(balanced_data)} samples across {len(self.classes)} classes")
        
        return balanced_data
    
    def preprocess_image(self, image_path):
        """Preprocess individual image for training"""
        try:
            # Read image
            if not os.path.exists(image_path):
                print(f"⚠️ Image not found: {image_path}")
                return None
            
            image = cv2.imread(image_path)
            if image is None:
                print(f"⚠️ Could not read image: {image_path}")
                return None
            
            # Convert BGR to RGB
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Resize to target size
            image = cv2.resize(image, (self.image_size, self.image_size))
            
            # Data augmentation (optional)
            # You can add rotation, brightness, contrast adjustments here
            
            return image
            
        except Exception as e:
            print(f"❌ Error processing {image_path}: {e}")
            return None
    
    def create_splits(self, data, train_ratio=0.7, val_ratio=0.15, test_ratio=0.15):
        """Split data into train/validation/test sets"""
        print(f"✂️ Creating data splits ({train_ratio:.1%}/{val_ratio:.1%}/{test_ratio:.1%})")
        
        # Group by label for stratified splitting
        label_groups = {}
        for item in data:
            label = item['label']
            if label not in label_groups:
                label_groups[label] = []
            label_groups[label].append(item)
        
        train_data, val_data, test_data = [], [], []
        
        for label, items in label_groups.items():
            # First split: separate test set
            train_val, test = train_test_split(
                items, test_size=test_ratio, random_state=42
            )
            
            # Second split: separate train and validation
            val_size = val_ratio / (train_ratio + val_ratio)
            train, val = train_test_split(
                train_val, test_size=val_size, random_state=42
            )
            
            train_data.extend(train)
            val_data.extend(val)
            test_data.extend(test)
            
            print(f"📊 {label}: {len(train)} train, {len(val)} val, {len(test)} test")
        
        return train_data, val_data, test_data
    
    def copy_images_to_splits(self, train_data, val_data, test_data):
        """Copy and organize images into train/val/test directories"""
        print("📂 Organizing images into train/val/test directories...")
        
        splits = [
            ('train', train_data),
            ('val', val_data), 
            ('test', test_data)
        ]
        
        for split_name, split_data in splits:
            split_dir = self.output_dir / split_name
            
            # Create class directories
            for class_name in self.classes:
                (split_dir / class_name).mkdir(exist_ok=True)
            
            # Copy images
            copied_count = 0
            for item in split_data:
                src_path = item['image_path']
                if not os.path.exists(src_path):
                    continue
                
                # Generate unique filename
                timestamp = item['timestamp'].replace(':', '-').replace('.', '-')
                filename = f"{item['id']}_{timestamp}.jpg"
                dst_path = split_dir / item['label'] / filename
                
                try:
                    # Preprocess and save image
                    image = self.preprocess_image(src_path)
                    if image is not None:
                        cv2.imwrite(str(dst_path), cv2.cvtColor(image, cv2.COLOR_RGB2BGR))
                        copied_count += 1
                except Exception as e:
                    print(f"⚠️ Error copying {src_path}: {e}")
            
            print(f"✅ {split_name}: {copied_count} images copied")
    
    def create_labels_file(self):
        """Create labels.txt file for the model"""
        labels_path = self.output_dir / 'labels.txt'
        with open(labels_path, 'w') as f:
            for label in self.classes:
                f.write(f"{label}\n")
        
        print(f"📝 Created labels file: {labels_path}")
        print(f"🏷️ Labels: {self.classes}")
    
    def generate_training_summary(self):
        """Generate summary of the preprocessing results"""
        summary = {
            'total_classes': len(self.classes),
            'classes': self.classes,
            'image_size': self.image_size,
            'directory_structure': {
                'train': str(self.output_dir / 'train'),
                'val': str(self.output_dir / 'val'),
                'test': str(self.output_dir / 'test'),
                'labels': str(self.output_dir / 'labels.txt')
            }
        }
        
        summary_path = self.output_dir / 'preprocessing_summary.json'
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"📄 Summary saved: {summary_path}")
        
        return summary
    
    def process(self):
        """Main preprocessing pipeline"""
        print("🚀 Starting data preprocessing pipeline...")
        
        # Load data
        data = self.load_data()
        
        # Filter and balance
        filtered_data = self.filter_and_balance_data(data)
        
        if len(filtered_data) == 0:
            print("❌ No valid data found for training!")
            return False
        
        # Create splits
        train_data, val_data, test_data = self.create_splits(filtered_data)
        
        # Copy images
        self.copy_images_to_splits(train_data, val_data, test_data)
        
        # Create labels file
        self.create_labels_file()
        
        # Generate summary
        summary = self.generate_training_summary()
        
        print("✅ Data preprocessing completed successfully!")
        print(f"📊 Ready for training with {len(self.classes)} classes")
        
        return True

def main():
    parser = argparse.ArgumentParser(description='Preprocess sign language data for training')
    parser.add_argument('--data', required=True, help='Path to exported JSON data file')
    parser.add_argument('--output', required=True, help='Output directory for processed data')
    parser.add_argument('--size', type=int, default=224, help='Image size (default: 224)')
    
    args = parser.parse_args()
    
    preprocessor = SignLanguageDataPreprocessor(args.data, args.output, args.size)
    success = preprocessor.process()
    
    if success:
        print("\n🎉 Preprocessing completed! You can now run train_model.py")
    else:
        print("\n❌ Preprocessing failed!")
        exit(1)

if __name__ == '__main__':
    main()