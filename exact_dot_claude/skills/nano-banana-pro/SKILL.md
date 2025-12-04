---
name: nano-banana-pro
description: |
  Generate images using Google Nano Banana Pro (Gemini 3 Pro Image).
  This is a generic image generation skill for any context.
  Use when users want to:
  - Create images from text descriptions
  - Generate artwork, photos, or illustrations
  - Use reference images for style or subject consistency
  - Create images with specific aspect ratios or resolutions

  Triggers: "generate image", "create image", "imagen", "nano banana",
  "make a picture", "draw", "illustrate"
---

# Nano Banana Pro Image Generation

Generate high-quality images using Google's Nano Banana Pro (Gemini 3 Pro Image) model. This skill provides generic image generation capabilities that can be extended for domain-specific use cases.

## Requirements

### Environment
- `GOOGLE_API_KEY` or `GEMINI_API_KEY` must be set
- Get API key from: https://aistudio.google.com/apikey

### Dependencies
```bash
pip install google-genai Pillow
```

Or use with `uv` (handles dependencies automatically):
```bash
uv run python .claude/scripts/nano_banana_pro.py "prompt"
```

## Model Capabilities

**Model**: Gemini 3 Pro Image (`gemini-3-pro-image-preview`)

| Feature | Options |
|---------|---------|
| Aspect Ratios | 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9 |
| Resolutions | 1K, 2K (default), 4K |
| Reference Images | Up to 5 images for style/subject consistency |
| Output Format | PNG |

## Usage

### CLI Usage

```bash
# Basic generation
uv run python .claude/scripts/nano_banana_pro.py "A sunset over mountains"

# With aspect ratio and resolution
uv run python .claude/scripts/nano_banana_pro.py "Product photo" --aspect 1:1 --resolution 4K

# With reference image
uv run python .claude/scripts/nano_banana_pro.py "Similar style" --reference existing.png

# Custom output path
uv run python .claude/scripts/nano_banana_pro.py "Scene" --output my_image.png
```

### Python Module Usage

```python
from nano_banana_pro import generate_image, create_client
from pathlib import Path

# Create client
client = create_client()

# Basic generation
result = generate_image(
    client=client,
    prompt="A beautiful landscape",
    output_path=Path("output.png"),
)

# With prompt enhancement callback
def enhance(prompt: str) -> str:
    return f"Professional photograph: {prompt}. Sharp focus, natural lighting."

result = generate_image(
    client=client,
    prompt="Portrait of a person",
    output_path=Path("portrait.png"),
    enhance_prompt=enhance,
    aspect_ratio="3:4",
    resolution="4K",
)

# With reference images
result = generate_image(
    client=client,
    prompt="Similar to this person",
    output_path=Path("similar.png"),
    reference_images=[Path("reference.png")],
)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | str | required | Image description |
| `output_path` | Path | auto | Where to save the image |
| `enhance_prompt` | Callable | None | Optional callback to modify prompt |
| `aspect_ratio` | str | "16:9" | Image proportions |
| `resolution` | str | "2K" | Image quality (1K, 2K, 4K) |
| `reference_images` | list[Path] | None | Reference images for consistency |

## Prompt Enhancement

The `enhance_prompt` callback allows domain-specific prompt modification:

```python
# Photography style
def photo_enhance(p: str) -> str:
    return f"Professional photograph: {p}. Natural lighting, sharp focus."

# Fantasy art style
def fantasy_enhance(p: str) -> str:
    return f"Epic fantasy illustration: {p}. Dramatic lighting, painterly."

# Product photography
def product_enhance(p: str) -> str:
    return f"Commercial product photo: {p}. White background, studio lighting."
```

## Reference Images

Reference images help maintain consistency:

- **Style transfer**: Use an existing image's artistic style
- **Subject consistency**: Keep a person/object looking the same across images
- **Scene matching**: Generate variations matching an existing scene

When using references, describe the relationship in your prompt:
- "This person in a different setting"
- "Similar style to the reference"
- "The same product from a different angle"

**Limit**: Maximum 5 reference images per generation.

## Aspect Ratio Guidelines

| Use Case | Recommended |
|----------|-------------|
| Square (social media) | 1:1 |
| Portrait/vertical | 3:4, 9:16 |
| Standard landscape | 16:9 |
| Ultrawide/cinematic | 21:9 |
| Photos | 3:2, 4:3 |

## Resolution Guidelines

| Use Case | Recommended |
|----------|-------------|
| Quick previews | 1K |
| General use | 2K (default) |
| Print/wallpaper | 4K |

## Output

Default output location: `./generated/image_YYYYMMDD_HHMMSS.png`

Use `--output` to specify a custom path.

## Error Handling

**"API key not set"**
```bash
export GOOGLE_API_KEY="your-key-here"  # pragma: allowlist secret
```

**"google-genai not installed"**
```bash
pip install google-genai Pillow
# Or use uv run prefix
```

**"No image generated"**
- Simplify the prompt
- Check for content policy violations
- Reduce reference images

**Rate limits**
- Typical limit: 10-20 images per minute
- Wait and retry if rate limited

## Extending This Skill

For domain-specific image generation (games, products, art styles), create a wrapper that:

1. Imports `nano_banana_pro` functions
2. Defines domain-specific prompt enhancement callbacks
3. Handles domain-specific reference image lookup
4. Sets appropriate default aspect ratios/resolutions

Example domain-specific wrapper pattern:

```python
from nano_banana_pro import generate_image, create_client

def enhance_for_my_domain(prompt: str) -> str:
    return f"My domain style: {prompt}. Specific attributes here."

def my_domain_generate(prompt: str, output: Path) -> Path | None:
    client = create_client()
    return generate_image(
        client=client,
        prompt=prompt,
        output_path=output,
        enhance_prompt=enhance_for_my_domain,
        aspect_ratio="16:9",  # Domain default
    )
```
