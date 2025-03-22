import boto3
import pandas as pd
from sqlalchemy.orm import Session
from datetime import datetime
import json
from typing import List, Dict

from .models import Transaction, Merchant, FraudAnalysis
from ..config.database import SessionLocal

class DataSync:
    def __init__(self, bucket_name: str):
        self.s3_client = boto3.client('s3')
        self.bucket_name = bucket_name
        self.db = SessionLocal()

    def sync_transactions(self, raw_path: str, processed_path: str):
        """Sincroniza datos de transacciones desde S3 a PostgreSQL"""
        try:
            # Leer datos procesados de S3
            transactions_df = pd.read_parquet(f"s3://{self.bucket_name}/{processed_path}")
            
            # Insertar en PostgreSQL
            for _, row in transactions_df.iterrows():
                transaction = Transaction(
                    transaction_id=row['transaction_id'],
                    timestamp=row['timestamp'],
                    amount=row['amount'],
                    merchant_id=row['merchant_id'],
                    card_number=row['card_number'],
                    is_fraud=row['is_fraud']
                )
                self.db.add(transaction)
            
            self.db.commit()
            print(f"Sincronizadas {len(transactions_df)} transacciones")
            
        except Exception as e:
            self.db.rollback()
            print(f"Error sincronizando transacciones: {str(e)}")
            raise

    def sync_merchants(self, merchant_path: str):
        """Sincroniza datos de comerciantes desde S3 a PostgreSQL"""
        try:
            # Leer datos de comerciantes de S3
            merchants_df = pd.read_parquet(f"s3://{self.bucket_name}/{merchant_path}")
            
            # Insertar en PostgreSQL
            for _, row in merchants_df.iterrows():
                merchant = Merchant(
                    merchant_id=row['merchant_id'],
                    merchant_name=row['merchant_name'],
                    category=row['category'],
                    location=row['location']
                )
                self.db.add(merchant)
            
            self.db.commit()
            print(f"Sincronizados {len(merchants_df)} comerciantes")
            
        except Exception as e:
            self.db.rollback()
            print(f"Error sincronizando comerciantes: {str(e)}")
            raise

    def sync_fraud_analysis(self, analysis_path: str):
        """Sincroniza análisis de fraude desde S3 a PostgreSQL"""
        try:
            # Leer análisis de fraude de S3
            analysis_df = pd.read_parquet(f"s3://{self.bucket_name}/{analysis_path}")
            
            # Insertar en PostgreSQL
            for _, row in analysis_df.iterrows():
                analysis = FraudAnalysis(
                    analysis_id=row['analysis_id'],
                    transaction_id=row['transaction_id'],
                    risk_score=row['risk_score'],
                    model_version=row['model_version'],
                    features_used=json.dumps(row['features_used'])
                )
                self.db.add(analysis)
            
            self.db.commit()
            print(f"Sincronizados {len(analysis_df)} análisis de fraude")
            
        except Exception as e:
            self.db.rollback()
            print(f"Error sincronizando análisis de fraude: {str(e)}")
            raise

    def close(self):
        """Cierra la conexión a la base de datos"""
        self.db.close() 