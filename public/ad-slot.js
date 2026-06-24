(function() {
    const container = document.getElementById('nano-ad-unit');
    if (!container) return;

    // 1. Evaluate context tags out of document layout
    const contextText = (document.title + " " + window.location.pathname).toLowerCase();
    let detectedCategory = 'travel';
    let accentColor = '#2563eb'; // Blue accent for travel

    if (contextText.includes('beauty') || contextText.includes('skincare') || contextText.includes('glow')) {
        detectedCategory = 'beauty';
        accentColor = '#e11d48'; // Rose accent for beauty
    }

    // 2. Fetch targeted matching rules
    fetch(`/api/blogs/match?category=${detectedCategory}`)
        .then(res => res.json())
        .then(campaigns => {
            if (!campaigns || !campaigns.length) return;
            
            // Pick the prime position payload row
            const ad = campaigns[0];
            const creatorId = 1; 

            container.innerHTML = `
            <div style="background: white; border-radius: 12px; padding: 20px; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); margin: 24px 0; font-family: -apple-system, sans-serif;">
                <div style="font-size: 11px; color: #94a3b8; text-transform: uppercase; margin-bottom: 6px; font-weight: 700; letter-spacing: 0.05em;">
                    Sponsored Recommendation
                </div>
                <h3 style="margin: 0 0 6px 0; font-size: 17px; color: #1e293b; font-weight: 700;">
                    ${ad.title}
                </h3>
                <p style="color: #64748b; margin: 0 0 14px 0; font-size: 13px; line-height: 1.5;">
                    ${ad.description}
                </p>
                <a href="/api/notifications/click?creator_id=${creatorId}&campaign_id=${ad.id}&redirect_url=${encodeURIComponent(ad.product_url)}&campaignTitle=${encodeURIComponent(ad.title)}"
                    target="_blank"
                    style="display: inline-block; background: ${accentColor}; color: white; text-decoration: none; padding: 10px 20px; border-radius: 8px; font-size: 13px; font-weight: 600;">
                    Explore Offer Now →
                </a>
            </div>
            `;
        })
        .catch(err => console.error("Ad slot module connection exception:", err));
})();