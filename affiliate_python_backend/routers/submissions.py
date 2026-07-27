from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
import re
from database import get_db
from middleware.auth import verify_token

router = APIRouter(prefix="/api/submissions", tags=["Submissions"])

class ConversionSchema(BaseModel):
    title: str
    orderTotal: float

class SubmissionCreateSchema(BaseModel):
    campaign_id: int
    post_url: str

def extract_tweet_id(url: str):
    match = re.search(r"status\/(\d+)", url)
    return match.group(1) if match else None

@router.post("/conversion")
def process_conversion(payload: ConversionSchema, user = Depends(verify_token)):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT id, commission_percentage FROM marketplace_products WHERE title = %s', 
            (payload.title,)
        )
        product_exists = cursor.fetchall()

        if product_exists:
            product_id = product_exists[0]['id']
            commission_percent = float(product_exists[0]['commission_percentage'] or 10.00)
            earnings = payload.orderTotal * (commission_percent / 100)

            cursor.execute(
                """INSERT INTO marketplace_submissions (product_id, creator_id, status, payout_amount, submitted_at) 
                   VALUES (%s, %s, 'approved', %s, NOW())""",
                (product_id, user['id'], earnings)
            )
            conn.commit()
            return {
                "success": True, 
                "message": f"Conversion recorded for '{payload.title}'. Commission applied: Rs.{earnings:.2f}"
            }
        
        raise HTTPException(status_code=404, detail="Product title not found in marketplace.")
    except HTTPException as he:
        raise he
    except Exception as err:
        raise HTTPException(status_code=500, detail=f"Database error: {str(err)}")
    finally:
        cursor.close()
        conn.close()

@router.post("/")
def create_submission(sub: SubmissionCreateSchema, user = Depends(verify_token)):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute('SELECT * FROM campaigns WHERE id = %s', (sub.campaign_id,))
        campaigns = cursor.fetchall()
        if not campaigns:
            raise HTTPException(status_code=404, detail="Campaign not found")

        campaign = campaigns[0]
        tweet_id = extract_tweet_id(sub.post_url)
        if not tweet_id:
            raise HTTPException(status_code=400, detail="Invalid tweet URL")

        payout = float(campaign['payout_per_post']) * 0.8

        cursor.execute(
            'INSERT INTO submissions (creator_id, campaign_id, post_url, status, payout_amount) VALUES (%s, %s, %s, "approved", %s)',
            (user['id'], sub.campaign_id, sub.post_url, payout)
        )
        conn.commit()
        return {"message": "Post verified and approved!", "payout_amount": payout}
    except HTTPException as he:
        raise he
    except Exception as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()

@router.get("/my-logs")
def get_creator_logs(user = Depends(verify_token)):
    print(f"DEBUG [GET /api/submissions/my-logs]: User ID {user['id']} requested their proof logs.")
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
           SELECT 
             s.id AS entry_id, 
             c.title AS entry_title, 
             s.status, 
             s.payout_amount, 
             s.submitted_at, 
             'Direct' AS source_type
           FROM submissions s 
           JOIN campaigns c ON s.campaign_id = c.id 
           WHERE s.creator_id = %s
           
           UNION ALL
           
           SELECT 
             m.id AS entry_id, 
             p.title AS entry_title, 
             m.status, 
             m.payout_amount, 
             m.submitted_at, 
             'Marketplace' AS source_type
           FROM marketplace_submissions m 
           JOIN marketplace_products p ON m.product_id = p.id 
           WHERE m.creator_id = %s
           ORDER BY submitted_at DESC
        """
        cursor.execute(query, (user['id'], user['id']))
        rows = cursor.fetchall()
        print(f"DEBUG [GET /api/submissions/my-logs]: Found {len(rows)} total logs for user {user['id']}.")
        return rows
    except Exception as err:
        print(f"ERROR [GET /api/submissions/my-logs]: {str(err)}")
        raise HTTPException(status_code=500, detail="Database error")
    finally:
        cursor.close()
        conn.close()