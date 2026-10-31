from datetime import datetime
from typing import Any, Dict, List, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from .firebase_config import db

app = FastAPI(
    title="Library Face Scan Backend",
    description="Backend Python untuk integrasi Kios Presensi Wajah & Firestore",
    version="1.0.0",
)


# ==========================================
# PYDANTIC MODELS (Validasi Data Masuk)
# ==========================================
class BorrowedBook(BaseModel):
  kode: str
  judul: str
  tanggal: str


class MemberModel(BaseModel):
  nama: str
  npm: str
  prodi: str
  tanggal_lahir: str
  lunas: bool = True
  foto: Optional[str] = ""
  biometrik_terdaftar: bool = False
  borrowed_books: List[BorrowedBook] = []
  kekurangan_iuran: str = "0"
  tagihan: Optional[str] = "0"


class BookModel(BaseModel):
  judul: str
  kode: str
  penulis: str
  kategori: str
  tahun_terbit: str
  deskripsi: str
  cover: Optional[str] = ""


class FaceScanRequest(BaseModel):
  npm: str
  nama: str
  foto: Optional[str] = ""


# ==========================================
# 1. ENDPOINT MANAJEMEN ANGGOTA (MEMBERS)
# ==========================================


@app.get("/members", response_model=List[Dict[str, Any]])
def get_members():
  """Mengambil semua data anggota dari Firestore"""
  try:
    docs = db.collection("members").stream()
    result = []
    for doc in docs:
      data = doc.to_dict()
      data["id"] = doc.id
      result.append(data)
    return result
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.post("/members")
def add_member(member: MemberModel):
  """Menambahkan anggota baru ke Firestore"""
  try:
    doc_ref = db.collection("members").document()
    member_data = member.dict()
    doc_ref.set(member_data)
    return {"status": "success", "id": doc_ref.id, "message": "Anggota berhasil ditambahkan"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.put("/members/{member_id}")
def update_member(member_id: str, member_data: dict):
  """Memperbarui data anggota"""
  try:
    doc_ref = db.collection("members").document(member_id)
    if not doc_ref.get().exists:
      raise HTTPException(status_code=404, detail="Anggota tidak ditemukan")
    doc_ref.update(member_data)
    return {"status": "success", "message": "Anggota berhasil diperbarui"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.delete("/members/{member_id}")
def delete_member(member_id: str):
  """Menghapus anggota dari Firestore"""
  try:
    doc_ref = db.collection("members").document(member_id)
    if not doc_ref.get().exists:
      raise HTTPException(status_code=404, detail="Anggota tidak ditemukan")
    doc_ref.delete()
    return {"status": "success", "message": "Anggota berhasil dihapus"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# 2. ENDPOINT KATALOG BUKU (BOOKS)
# ==========================================


@app.get("/books", response_model=List[Dict[str, Any]])
def get_books():
  """Mengambil katalog buku dari Firestore"""
  try:
    docs = db.collection("books").stream()
    result = []
    for doc in docs:
      data = doc.to_dict()
      data["id"] = doc.id
      result.append(data)
    return result
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.post("/books")
def add_book(book: BookModel):
  """Menambahkan buku baru"""
  try:
    doc_ref = db.collection("books").document()
    book_data = book.dict()
    doc_ref.set(book_data)
    return {"status": "success", "id": doc_ref.id, "message": "Buku berhasil ditambahkan"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.put("/books/{book_id}")
def update_book(book_id: str, book_data: dict):
  """Memperbarui data buku"""
  try:
    doc_ref = db.collection("books").document(book_id)
    if not doc_ref.get().exists:
      raise HTTPException(status_code=404, detail="Buku tidak ditemukan")
    doc_ref.update(book_data)
    return {"status": "success", "message": "Buku berhasil diperbarui"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


@app.delete("/books/{book_id}")
def delete_book(book_id: str):
  """Menghapus buku"""
  try:
    doc_ref = db.collection("books").document(book_id)
    if not doc_ref.get().exists:
      raise HTTPException(status_code=404, detail="Buku tidak ditemukan")
    doc_ref.delete()
    return {"status": "success", "message": "Buku berhasil dihapus"}
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# 3. ENDPOINT FACE SCAN & VISITOR LOG (STUB)
# ==========================================


@app.post("/scan-face")
def scan_face_endpoint(scan: FaceScanRequest):
  """Endpoint simulasi deteksi wajah (nanti diisi algoritma OpenCV/Face Recognition).

  Mencatat presensi ke visitor_logs dan memperbarui statistik dashboard.
  """
  try:
    now = datetime.now()
    time_str = now.strftime("%H:%M")

    # Cek log terakhir untuk menentukan apakah mahasiswa masuk atau keluar (opsional logic)
    # Untuk contoh sederhana, kita asumsikan aksi "Mengunjungi"
    aksi = "Mengunjungi"

    new_log = {
        "aksi": aksi,
        "user": f"{scan.nama}_{scan.npm}",
        "nama": scan.nama,
        "npm": scan.npm,
        "foto": scan.foto or "",
        "waktu": time_str,
        "timestamp": firestore.SERVER_TIMESTAMP,
    }

    # Simpan ke collection 'visitor_logs'
    db.collection("visitor_logs").add(new_log)

    return {
        "status": "success",
        "message": f"Presensi berhasil dicatat untuk {scan.nama} ({scan.npm})",
        "aksi": aksi,
        "waktu": time_str,
    }
  except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
  import uvicorn

  uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)