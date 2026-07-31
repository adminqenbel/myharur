"""Image upload endpoint - stores files to /static/uploads/."""
import os
import uuid
import shutil
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.api import deps
from app.models.user import User as UserModel

router = APIRouter()

UPLOAD_DIR = os.path.join("static", "uploads")
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Upload an image with strict security validation and sanitization."""
    import magic
    from io import BytesIO
    from PIL import Image

    # Basic extension validation
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"File type '{ext}' not allowed. Use: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File too large. Max 5MB.")

    # MIME type validation via python-magic
    mime_type = magic.from_buffer(contents, mime=True)
    if not mime_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file signature (not an image).")

    # Image sanitization via Pillow (strips EXIF and malicious payloads)
    try:
        image = Image.open(BytesIO(contents))
        image.verify()  # verify format
        # reopen to strip EXIF and save safely
        image = Image.open(BytesIO(contents))
        # convert to RGB if needed
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
        sanitized_io = BytesIO()
        image.save(sanitized_io, format="JPEG", quality=85)
        sanitized_contents = sanitized_io.getvalue()
        ext = ".jpg"  # enforce safe extension after sanitization
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Image validation failed: corrupted or malicious file. {str(e)}")

    unique_name = f"{uuid.uuid4().hex}{ext}"
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    file_path = os.path.join(UPLOAD_DIR, unique_name)

    with open(file_path, "wb") as f:
        f.write(sanitized_contents)

    return {"url": f"/static/uploads/{unique_name}", "filename": unique_name}
