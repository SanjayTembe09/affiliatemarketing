from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, HttpUrl
from database import get_db
from middleware.auth import verify_token

router = APIRouter(prefix="/api/marketplace", tags=["Marketplace"])

class ProductCreateSchema(BaseModel):
    title: str
    description: str
    product_url: str
    image_url: str = None
    price: float
    commission_percentage: float

@router.get("/")
def get_marketplace_products(user = Depends(verify_token)):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        if user['role'] == 'brand':
            cursor.execute(
                'SELECT * FROM marketplace_products WHERE status = "active" AND brand_id = %s ORDER BY created_at DESC', 
                (user['id'],)
            )
        else:
            cursor.execute(
                'SELECT * FROM marketplace_products WHERE status = "active" ORDER BY created_at DESC'
            )
        rows = cursor.fetchall()
        print(f"DEBUG [GET /api/marketplace/]: Found {len(rows)} products in database.")
        return rows
    except Exception as err:
        print(f"ERROR [GET /api/marketplace/]: {str(err)}")
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()

@router.post("/")
def add_marketplace_product(product: ProductCreateSchema, user = Depends(verify_token)):
    if user['role'] != 'brand':
        raise HTTPException(status_code=403, detail="Access denied: Only brands can add products.")
    
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """INSERT INTO marketplace_products 
            (brand_id, title, description, product_url, image_url, price, commission_percentage, status) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'active')""",
            (
                user['id'], product.title, product.description, 
                product.product_url, product.image_url, 
                product.price, product.commission_percentage
            )
        )
        conn.commit()
        return {
            "id": cursor.lastrowid, 
            "success": True,
            "message": "Affiliate product added to marketplace successfully!"
        }
    except Exception as err:
        raise HTTPException(status_code=500, detail=f"Database rejection: {str(err)}")
    finally:
        cursor.close()
        conn.close()