from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from backend.database import Base

class TMI(Base):
    __tablename__ = "tb_tmi"

    tmi_num = Column(Integer, primary_key=True, autoincrement=True)
    contents = Column(String(100), nullable=False)
    field = Column(String(50), nullable=False)
    created_at = Column(DateTime, default=datetime.now)
