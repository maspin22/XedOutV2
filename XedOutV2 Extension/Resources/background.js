// Background script for Safari extension
// Acts as a bridge between content script and native Swift handler

console.log('[X Filter Background] Background script loaded');

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('[X Filter Background] Received message:', request.action);
  
  if (request.action === 'analyzeContent') {
    // Forward to native handler or handle directly
    analyzeContentWithAPI(request.text, request.imageUrls, request.apiKey, request.prompt)
      .then(result => {
        console.log('[X Filter Background] Analysis result:', result);
        sendResponse({ success: true, result: result });
      })
      .catch(error => {
        console.error('[X Filter Background] Error:', error);
        sendResponse({ success: false, error: error.message });
      });
    
    // Return true to indicate async response
    return true;
  }
});

async function analyzeContentWithAPI(text, imageUrls, apiKey, prompt) {
  try {
    // Build the prompt
    let fullPrompt = `${prompt} Respond with only "true" or "false":\n`;
    fullPrompt += `Post text: "${text}"\n`;
    
    if (imageUrls && imageUrls.length > 0) {
      fullPrompt += `The post contains ${imageUrls.length} image(s). Please consider the images in your analysis.`;
    }
    
    // Prepare messages array
    let messages = [{
      role: "user",
      content: fullPrompt
    }];
    
    // Add images if available
    if (imageUrls && imageUrls.length > 0) {
      const contentArray = [{
        type: "text",
        text: fullPrompt
      }];
      
      // Add up to 2 images to avoid token limits
      for (const imageUrl of imageUrls.slice(0, 2)) {
        contentArray.push({
          type: "image_url",
          image_url: {
            url: imageUrl
          }
        });
      }
      
      messages[0].content = contentArray;
    }
    
    console.log('[X Filter Background] Making API request to OpenAI...');
    
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.7
      })
    });
    
    console.log('[X Filter Background] HTTP Status:', response.status, response.statusText);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('[X Filter Background] HTTP Error:', response.status, errorText);
      throw new Error(`HTTP ${response.status}: ${errorText}`);
    }
    
    const data = await response.json();
    console.log('[X Filter Background] API Response:', data);
    
    if (data.error) {
      console.error('[X Filter Background] API Error:', data.error);
      throw new Error(data.error.message || JSON.stringify(data.error));
    }
    
    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      console.error('[X Filter Background] Invalid response structure:', data);
      throw new Error('Invalid API response structure');
    }
    
    const result = data.choices[0].message.content.toLowerCase().trim();
    return result === 'true';
    
  } catch (error) {
    console.error('[X Filter Background] Error:', error);
    throw error;
  }
}
