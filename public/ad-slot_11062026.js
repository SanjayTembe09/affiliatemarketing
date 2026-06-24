// This script fetches a random active campaign and displays it
(function() {
    const container = document.getElementById('nano-ad-unit');
    if (!container) return;

    fetch('/api/campaigns')
        .then(res => res.json())
        .then(campaigns => {
            if (!campaigns.length) return;
            
            // Picks a travel-related campaign or falls back
            const ad = campaigns.find(c => 
                c.title.toLowerCase().includes('travel') || 
                c.title.toLowerCase().includes('island') ||
                c.title.toLowerCase().includes('tour') ||
                c.title.toLowerCase().includes('james bond')
            ) || campaigns[campaigns.length - 1]; 
            
            const creatorId = 1; 

            container.innerHTML = `
            <div style="
                background:white;
                border-radius:12px;
                padding:16px;
                border:1px solid #e2e8f0;
                box-shadow:0 2px 8px rgba(0,0,0,0.08);
                margin:20px 0;
                font-family: sans-serif;
            ">
                <div style="
                    font-size:11px;
                    color:#94a3b8;
                    text-transform:uppercase;
                    margin-bottom:8px;
                ">
                    Sponsored
                </div>

                <h3 style="margin-bottom:8px; font-size: 16px; color: #1e293b;">
                    ${ad.title}
                </h3>

                <p style="color:#64748b; margin-bottom:12px; font-size: 13px; line-height: 1.4;">
                    ${ad.description}
                </p>

                <a href="/r/${ad.id}"
                    target="_blank"
                    style="
                        display:inline-block;
                        background:#2563eb;
                        color:white;
                        text-decoration:none;
                        padding:10px 18px;
                        border-radius:8px;
                        font-size: 13px;
                        font-weight: 600;
                    ">
                    Learn More
                </a>
            </div>
            `;
        });
})();