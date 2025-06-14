# app/utils/image_utils.py
from pathlib import Path
from datetime import date, datetime
from PIL import Image, ImageOps
import uuid, math

ROOT = Path(__file__).resolve().parents[2] / "images"
ROOT.mkdir(exist_ok=True)
BASE_URL_PATH = "/images" 

def _date_key(d):
    if isinstance(d, (date, datetime)):
        return d.strftime("%Y%m%d")
    return datetime.strptime(d[:10], "%Y-%m-%d").strftime("%Y%m%d")

def save_generated_images(image_paths, diary_date, user_id):
    key   = _date_key(diary_date)
    uid   = str(user_id)
    uniq  = uuid.uuid4().hex

    thumb_dir  = ROOT / "thumb";  thumb_dir.mkdir(parents=True, exist_ok=True)
    merged_dir = ROOT / "merged"; merged_dir.mkdir(parents=True, exist_ok=True)

    # ── 썸네일 (첫 장 50 %) ────────────────────────────────────
    img0   = Image.open(image_paths[0]).convert("RGB")
    thumb  = img0.resize((img0.width//2, img0.height//2))
    thumb_rel = f"thumb/{uid}_{key}_{uniq}.png"
    thumb_path = thumb_dir / f"{uid}_{key}_{uniq}.png"
    thumb.save(thumb_path)

    # ── 병합 (2×2 + 여백 20px) ──────────────────────────────
    imgs   = [Image.open(p).convert("RGB") for p in image_paths[:4]]
    w, h   = imgs[0].size
    pad    = 20      # 여백(px)
    merged = Image.new("RGB", (w*2 + pad*3, h*2 + pad*3), color="white")

    for i, im in enumerate(imgs):
        r, c = divmod(i, 2)
        x = pad + c*(w+pad)
        y = pad + r*(h+pad)
        merged.paste(im, (x, y))

    merged_rel = f"merged/{uid}_{key}_{uniq}.png"
    merged_path = merged_dir / f"{uid}_{key}_{uniq}.png"
    merged.save(merged_path)

    def _clean(p: str) -> str:
        """
        ▸ 윈도 경로 구분자 '\' → '/'
        ▸ '/images/images/…' 같이 두 번 붙은 경우 한 번만 남김
        """
        p = p.replace("\\", "/")
        return p.replace("/images/images", "/images")

    thumb_url  = _clean(f"{BASE_URL_PATH}/{thumb_rel}")
    merged_url = _clean(f"{BASE_URL_PATH}/{merged_rel}")

    return thumb_url, merged_url   
