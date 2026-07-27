from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from database import get_db
from middleware.auth import verify_token

router = APIRouter(prefix="/api/campaigns", tags=["Campaigns"])

class CampaignCreateSchema(BaseModel):
    title: str
    description: str
    product_url: str
    payout_per_post: float
    required_hashtag: str
    category: str

@router.get("/")
def get_campaigns(user = Depends(verify_token)):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        if user['role'] == 'brand':
            cursor.execute('SELECT * FROM campaigns WHERE brand_id = %s', (user['id'],))
        else:
            cursor.execute('SELECT * FROM campaigns WHERE status = "active"')
        rows = cursor.fetchall()
        return rows
    except Exception as err:
        raise HTTPException(status_code=500, detail="Failed to fetch campaigns")
    finally:
        cursor.close()
        conn.close()

@router.post("/")
def create_campaign(campaign: CampaignCreateSchema, user = Depends(verify_token)):
    if user['role'] != 'brand':
        raise HTTPException(status_code=403, detail="Unauthorized: Only brands can create campaigns")
    
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
          INSERT INTO campaigns 
          (brand_id, title, description, product_url, payout_per_post, required_hashtag, category, status) 
          VALUES (%s, %s, %s, %s, %s, %s, %s, 'active')
        """
        values = (
            user['id'], campaign.title, campaign.description, 
            campaign.product_url, campaign.payout_per_post, 
            campaign.required_hashtag, campaign.category
        )
        cursor.execute(query, values)
        conn.commit()
        return {"id": cursor.lastrowid, "message": "Campaign created successfully"}
    except Exception as err:
        raise HTTPException(status_code=500, detail="Failed to create campaign")
    finally:
        cursor.close()
        conn.close()