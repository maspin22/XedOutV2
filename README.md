# XedOut

A Safari extension for filtering unwanted content on X (formerly Twitter) using AI-powered content analysis.

## Features

- 🎥 **Video Filter**: Automatically hide posts containing videos
- 🤖 **AI-Powered Custom Filter**: Use OpenAI's GPT-4o-mini to filter posts based on custom criteria
- 📸 **Image Analysis**: Analyzes both text and images in posts for comprehensive filtering
- 📢 **Ad Blocker**: Hide promoted posts and advertisements
- ⚙️ **Customizable Prompts**: Define your own filtering criteria (e.g., "political content", "sports", etc.)


<img width="783" height="891" alt="Screenshot 2025-10-05 at 6 26 41 PM" src="https://github.com/user-attachments/assets/fb1c1d70-d953-4627-8501-0ff220bd4927" />

## Installation

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- Safari 17.0 or later

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/XedOutV2.git
   cd XedOutV2
   ```

2. Open the project in Xcode:
   ```bash
   open XedOutV2.xcodeproj
   ```

3. Build and run the project (⌘+R)

4. Enable the extension in Safari:
   - Safari → Settings → Extensions
   - Enable "X Content Filter"

## Configuration

### API Key Setup

1. Get an OpenAI API key from [platform.openai.com](https://platform.openai.com/)
2. Add billing credits (minimum $5 recommended)
3. Click the extension icon in Safari
4. Enter your API key and click "Save"

### Custom Filter Prompt

Customize what content gets filtered by setting your own prompt:

**Examples:**
- `"Analyze if the following content is political in nature."`
- `"Determine if this post contains sports-related content."`
- `"Check if this post discusses cryptocurrency or NFTs."`

The AI will respond with true/false and hide matching posts.

## Usage

1. Navigate to [x.com](https://x.com)
2. Click the extension icon
3. Toggle filters on/off:
   - **Video Filter**: Hide all video posts
   - **Custom Filter**: Use AI to filter based on your prompt
   - **Ad Filter**: Hide promoted content

Posts matching your filters will be automatically hidden as you scroll.

## Cost

Using **gpt-4o-mini** (the default model):
- Text-only analysis: ~$0.001 per post
- With images: ~$0.01 per post
- $10 in credits ≈ 10,000 text posts or 1,000 posts with images

## Privacy

- All filtering happens locally in your browser
- API calls are made directly from the extension to OpenAI
- No data is stored or sent to third-party servers
- Your API key is stored locally in Safari

## Architecture

```
Content Script (JS) → Background Script (JS) → OpenAI API
     ↓                        ↓
  X/Twitter              Analyzes Content
   Website                Returns Result
```

## Development

### Project Structure
```
XedOutV2/
├── XedOutV2/                      # Main app
│   ├── AppDelegate.swift
│   ├── ViewController.swift
│   └── Resources/
├── XedOutV2 Extension/            # Safari extension
│   ├── SafariWebExtensionHandler.swift
│   └── Resources/
│       ├── manifest.json
│       ├── background.js          # API calls
│       ├── contentScript.js       # Content filtering
│       ├── popup.html/js/css      # Extension UI
│       └── icons/
└── README.md
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this project however you'd like.

## Troubleshooting

### "insufficient_quota" error
- Add credits to your OpenAI account at [platform.openai.com/account/billing](https://platform.openai.com/account/billing)

### Extension not working
- Check that the extension is enabled in Safari Settings
- Reload the X/Twitter page
- Check the Safari Console for error messages

### API key not saving
- Make sure you entered the key correctly
- Try re-entering the key and clicking "Save" again

## Roadmap

- [ ] Support for additional AI providers (Anthropic Claude, Google Gemini)
- [ ] Filter statistics and analytics
- [ ] Whitelist/blacklist specific accounts
- [ ] Export/import filter configurations
- [ ] Multiple filter profiles

## Support

For issues, questions, or suggestions, please [open an issue](https://github.com/yourusername/XedOutV2/issues).

---

Made with ❤️ for a better browsing experience
