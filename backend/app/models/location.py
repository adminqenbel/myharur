from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.db.session import Base

class State(Base):
    __tablename__ = "states"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    is_active = Column(Boolean, default=True)

    districts = relationship("District", back_populates="state")

class District(Base):
    __tablename__ = "districts"
    id = Column(Integer, primary_key=True, index=True)
    state_id = Column(Integer, ForeignKey("states.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    is_active = Column(Boolean, default=True)

    state = relationship("State", back_populates="districts")
    taluks = relationship("Taluk", back_populates="district")

class Taluk(Base):
    __tablename__ = "taluks"
    id = Column(Integer, primary_key=True, index=True)
    district_id = Column(Integer, ForeignKey("districts.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    is_active = Column(Boolean, default=True)

    district = relationship("District", back_populates="taluks")
    towns = relationship("Town", back_populates="taluk")
    villages = relationship("Village", back_populates="taluk")

class Town(Base):
    __tablename__ = "towns"
    id = Column(Integer, primary_key=True, index=True)
    taluk_id = Column(Integer, ForeignKey("taluks.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    pincode = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)

    taluk = relationship("Taluk", back_populates="towns")

class Village(Base):
    __tablename__ = "villages"
    id = Column(Integer, primary_key=True, index=True)
    taluk_id = Column(Integer, ForeignKey("taluks.id"), nullable=False)
    name = Column(String, index=True, nullable=False)
    panchayat = Column(String, nullable=True) # E.g., which panchayat this village belongs to
    pincode = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)

    taluk = relationship("Taluk", back_populates="villages")
