// This script fetches a random active campaign and displays it
(function() {
    const container = document.getElementById('nano-ad-unit');
    if (!container) return;

    fetch('/api/campaigns')
        .then(res => res.json())
        .then(campaigns => {
            if (!campaigns.length) return;
            
            // Pick the first active campaign for now
            //const ad = campaigns[0]; 

            // NEW - picks a travel-related campaign
            const ad = campaigns.find(c => 
            c.title.toLowerCase().includes('travel') || 
            c.title.toLowerCase().includes('island') ||
            c.title.toLowerCase().includes('tour') ||
            c.title.toLowerCase().includes('james bond')
            ) || campaigns[campaigns.length - 1]; // fallback to last campaign
            
            // We'll need a creator ID for testing (Creator ID 1)
            const creatorId = 1; 

            /*container.innerHTML = `
                <div style="border: 1px solid #ddd; padding: 15px; border-radius: 12px; max-width: 300px; font-family: sans-serif; background: white; cursor: pointer;" 
                     onclick="window.open('/r/test-code-123', '_blank')">
                    <span style="font-size: 10px; color: #999; text-transform: uppercase;">Sponsored</span>
                    <h4 style="margin: 5px 0; color: #2563eb;">${ad.title}</h4>
                    <p style="font-size: 12px; color: #64748b;">${ad.description}</p>
                    <button style="width: 100%; background: #2563eb; color: white; border: none; padding: 8px; border-radius: 6px; margin-top: 10px; cursor: pointer;">
                        View Product
                    </button>
                </div>
            `; */

            container.innerHTML = `
            <div style="
                background:white;
                border-radius:12px;
                padding:16px;
                border:1px solid #e2e8f0;
                box-shadow:0 2px 8px rgba(0,0,0,0.08);
                margin:20px 0;
            ">
                <div style="
                    font-size:11px;
                    color:#94a3b8;
                    text-transform:uppercase;
                    margin-bottom:8px;
                ">
                    Sponsored
                </div>

                <h3 style="margin-bottom:8px;">
                    ${ad.title}
                </h3>

                <p style="color:#64748b; margin-bottom:12px;">
                    ${ad.description}
                </p>

                <a href="/r/test-code-123"
                    style="
                        display:inline-block;
                        background:#2563eb;
                        color:white;
                        text-decoration:none;
                        padding:10px 18px;
                        border-radius:8px;
                    ">
                    Learn More
                </a>
            </div>
            `;
        });
})();