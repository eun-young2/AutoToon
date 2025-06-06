from sqlalchemy import Column, String, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.schema import PrimaryKeyConstraint

from .user import Base as UserBase  # Base가 이미 선언된 곳을 임포트하셔도 됩니다.

Base = UserBase  # models/user.py에서 선언한 declarative_base()를 재사용한다면 이렇게 설정하세요.

class Attendance(Base):
    __tablename__ = "tb_attendance"
    # 복합 PK: (user_id, date) → 한 사용자는 같은 날짜에 여러 레코드를 만들 수 없다.
    user_id = Column(String(100), nullable=False)
    date = Column(Date, nullable=False)

    __table_args__ = (
        PrimaryKeyConstraint("user_id", "date", name="pk_attendance_user_date"),
    )
