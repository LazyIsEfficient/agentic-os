# Deck Generator Workflow

## Step 1: Content Spec

Accept slide content in any format. Normalize to this structure per slide:
- **Title**: Bold headline
- **Body**: Key points, stats, or narrative
- **Visual cues**: Icons, diagrams, layouts described in words

If user provides a markdown file with `---` separators, parse each section as a slide.
If user provides a topic only, generate 10–14 slides following standard deck structures.

## Step 2: Style Selection

| Style | Description |
|-------|-------------|
| `whiteboard` | Hand-drawn sketch on white. Black ink, orange accents. |
| `corporate` | Navy/white/gold. Clean sans-serif. Professional. |
| `minimalist` | Pure white, electric blue accent. Maximum negative space. |
| `dark-tech` | Near-black background, neon green. Terminal aesthetic. |
| `playful` | Bright pastels, rounded shapes. Modern startup vibe. |
| `editorial` | Black/white with red spot color. Magazine aesthetic. |

Default: `whiteboard`. User can specify any preset or describe a custom style.

## Step 3: Generate

```bash
export GEMINI_API_KEY="your-gemini-api-key"

python3 scripts/generate-deck.py \
  --content slides.json \
  --style whiteboard \
  --title "Deck Title" \
  [--output-dir ./output] \
  [--aspect 16:9]
```

The script:
1. Generates each slide image via Imagen 4.0 API
2. Saves all images to the output directory
3. Optionally creates a Google Slides presentation (requires Google Slides API credentials)
4. Returns paths to all generated images

## Step 4: Regenerate Individual Slides

```bash
python3 scripts/generate-deck.py \
  --content slides.json \
  --style whiteboard \
  --slides 3,7 \
  --output-dir ./output
```

## Content JSON Format

```json
[
  {"name": "01-title", "prompt": "Title slide: 'Your Deck Title' with company logo placeholder"},
  {"name": "02-problem", "prompt": "Problem slide showing frustrated marketer staring at dashboard with declining metrics"},
  {"name": "03-solution", "prompt": "Solution slide: AI agent workflow diagram with 3 connected boxes"}
]
```

## Google Slides Integration (Optional)

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
python3 scripts/generate-deck.py \
  --content slides.json \
  --style whiteboard \
  --title "My Deck" \
  --google-slides \
  --google-account your-email@example.com
```

## Key Details

- **Cost**: ~4 cents per image. A 14-slide deck costs roughly 56 cents.
- **Speed**: ~2 minutes for 14 slides.
- **API**: Imagen 4.0 via Google's Generative Language API
- **Auth**: Set `$GEMINI_API_KEY` environment variable
- **Aspect ratios**: 16:9 (default), 1:1, 4:3, 3:4, 9:16
- **Image models**: `imagen-4.0-generate-001` (best quality), `imagen-4.0-fast-generate-001` (faster)
