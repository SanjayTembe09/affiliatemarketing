from fastapi import APIRouter, HTTPException
from fastapi.responses import RedirectResponse
from database import get_db

router = APIRouter(prefix="/r", tags=["Redirect"])

@router.get("/{campaign_id}")
def redirect_campaign(campaign_id: str):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute('SELECT title FROM campaigns WHERE id = %s', (campaign_id,))
        rows = cursor.fetchall()
        campaign_title = rows[0]['title'] if rows else 'Active Campaign'

        # Redirect target simulating product interaction view
        return RedirectResponse(url=f"/product.html?campaignId={campaign_id}&title={campaign_title}")
    except Exception as err:
        return RedirectResponse(url="/")
    finally:
        cursor.close()
        conn.close()