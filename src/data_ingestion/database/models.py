from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class Transaction(Base):
    """Modelo para transacciones de tarjetas de crédito"""
    __tablename__ = 'transactions'

    transaction_id = Column(String(50), primary_key=True)
    timestamp = Column(DateTime, nullable=False)
    amount = Column(Float, nullable=False)
    merchant_id = Column(String(50), ForeignKey('merchants.merchant_id'))
    card_number = Column(String(50), nullable=False)
    is_fraud = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    merchant = relationship("Merchant", back_populates="transactions")
    fraud_analysis = relationship("FraudAnalysis", back_populates="transaction", uselist=False)

class Merchant(Base):
    """Modelo para comerciantes"""
    __tablename__ = 'merchants'

    merchant_id = Column(String(50), primary_key=True)
    merchant_name = Column(String(100), nullable=False)
    category = Column(String(50))
    location = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relaciones
    transactions = relationship("Transaction", back_populates="merchant")

class FraudAnalysis(Base):
    """Modelo para análisis de fraude"""
    __tablename__ = 'fraud_analysis'

    analysis_id = Column(String(50), primary_key=True)
    transaction_id = Column(String(50), ForeignKey('transactions.transaction_id'))
    risk_score = Column(Float, nullable=False)
    analysis_timestamp = Column(DateTime, default=datetime.utcnow)
    model_version = Column(String(50))
    features_used = Column(String(500))  # JSON string de características

    # Relaciones
    transaction = relationship("Transaction", back_populates="fraud_analysis") 