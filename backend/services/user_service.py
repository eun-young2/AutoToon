from datetime import datetime
from backend.models.user import User

def save_kakao_user_to_db(kakao_user, db):
    print("save_kakao_user_to_db 함수가 호출되었습니다.", flush=True)
    user_id = str(kakao_user["id"])
    user_name = kakao_user["kakao_account"].get("name")
    user_nick = (
        kakao_user.get("properties", {}).get("nickname")
        or kakao_user["kakao_account"].get("profile", {}).get("nickname")
    )
    gender_str = kakao_user["kakao_account"].get("gender")
    user_gender = 1 if gender_str == "female" else 0 if gender_str == "male" else None
    user_age_range = kakao_user["kakao_account"].get("age_range")
    created_at = kakao_user.get("connected_at")
    if created_at:
        created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))

    existing_user = db.query(User).filter(User.user_id == user_id).first()
    if existing_user:
        existing_user.user_name = user_name
        existing_user.user_nick = user_nick
        existing_user.user_gender = user_gender
        existing_user.user_age_range = user_age_range
        existing_user.created_at = created_at
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            print("DB update 에러:", e)
            raise e
        return

    db_user = User(
        user_id=user_id,
        user_name=user_name,
        user_nick=user_nick,
        user_gender=user_gender,
        user_age_range=user_age_range,
        created_at=created_at,
        credit=300,           # 가입과 동시에 300 세팅
        correction_tape_item=0,
        diary_item=0
    )
    try:
        db.add(db_user)
        db.commit()
        print("DB insert 성공")
    except Exception as e:
        db.rollback()
        print("DB insert 에러:", e)
        raise e
