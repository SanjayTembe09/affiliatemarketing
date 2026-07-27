from fastapi import APIRouter, HTTPException
from database import get_db

router = APIRouter(prefix="/api/blogs", tags=["Blogs"])

@router.get("/")
def get_blogs():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute('SELECT * FROM blog_sites WHERE status = "active"')
        blogs = cursor.fetchall()
        
        cursor.execute('SELECT * FROM campaigns WHERE status = "active"')
        campaigns = cursor.fetchall()

        blogs_with_campaigns = []
        for blog in blogs:
            blog_cat = (blog.get('category') or '').lower().strip()
            filtered_campaigns = [
                c for c in campaigns 
                if (c.get('category') or '').lower().strip() == blog_cat
            ]
            blog_copy = dict(blog)
            blog_copy['campaigns'] = filtered_campaigns
            blogs_with_campaigns.append(blog_copy)

        return blogs_with_campaigns
    except Exception as err:
        raise HTTPException(status_code=500, detail=str(err))
    finally:
        cursor.close()
        conn.close()