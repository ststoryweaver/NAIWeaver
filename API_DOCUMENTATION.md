# NovelAI API V4.5 Documentation

## Endpoint
`POST https://image.novelai.net/ai/generate-image`

## Headers
| Header | Value |
|---|---|
| `Authorization` | `Bearer <API_KEY>` |
| `Content-Type` | `application/json` |

## Request Body

```json
{
  "input": "<prompt with styles applied>",
  "model": "nai-diffusion-4-5-full",
  "action": "generate | img2img",
  "parameters": { ... }
}
```

## Parameters Reference

### Core Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `params_version` | int | `3` | API parameter version |
| `width` | int | `832` | Image width in pixels |
| `height` | int | `1216` | Image height in pixels |
| `scale` | double | `6.0` | Guidance scale (CFG) |
| `sampler` | string | `"k_euler_ancestral"` | Sampling algorithm |
| `steps` | int | `28` | Number of denoising steps |
| `seed` | int | — | Random seed for reproducibility |
| `n_samples` | int | `1` | Number of images to generate |
| `noise_schedule` | string | `"karras"` | Noise schedule type |
| `uc` | string | — | Negative prompt (undesired content) |

### Post-Processing

| Parameter | Type | Default | Description |
|---|---|---|---|
| `sm` | bool | `false` | SMEA post-processing |
| `sm_dyn` | bool | `false` | Dynamic SMEA |
| `dynamic_thresholding` | bool | `false` | Decrisper |

### V4.5 Prompt Structure

The V4.5 API uses structured prompt objects instead of plain strings for multi-character support:

```json
{
  "v4_prompt": {
    "caption": {
      "base_caption": "scene description tags...",
      "char_captions": [
        {
          "char_caption": "character 1 tags...",
          "centers": [{"x": 0.3, "y": 0.5}]
        },
        {
          "char_caption": "character 2 tags...",
          "centers": [{"x": 0.7, "y": 0.5}]
        }
      ]
    },
    "use_coords": true,
    "use_order": true
  },
  "v4_negative_prompt": {
    "caption": {
      "base_caption": "lowres, {bad}, error...",
      "char_captions": [
        {"char_caption": "lowres, bad quality...", "centers": [{"x": 0.5, "y": 0.5}]},
        {"char_caption": "lowres, bad quality...", "centers": [{"x": 0.5, "y": 0.5}]}
      ]
    }
  }
}
```

- `use_coords`: Enable pixel-coordinate character positioning (requires `centers` in char_captions)
- `use_order`: Enable character ordering
- `char_captions`: Array of character objects with their prompts and center positions

### Character Interactions

Interaction tags are prepended to character captions:
- **Source action**: `source#action_name, <character tags>`
- **Target action**: `target#action_name, <character tags>`
- **Mutual action**: `mutual#action_name, <character tags>`

NAIWeaver supports multi-participant interactions where multiple characters can share the same source or target role. The interaction tag is prepended to each participating character's caption independently. For example, two source characters each get `source#holding_hands, ...` prepended, while the single target gets `target#holding_hands, ...`.

### Img2Img / Inpainting Parameters

| Parameter | Type | Description |
|---|---|---|
| `image` | string | Base64-encoded source image |
| `mask` | string | Base64-encoded mask image (white = regenerate, black = keep) |
| `strength` | double | How much to transform the source (0.0-1.0) |
| `noise` | double | Additional noise to inject (0.0-1.0) |
| `extra_noise_seed` | int | Seed for extra noise (usually same as main seed) |
| `add_original_image` | bool | Whether to blend with original |

Set `action: "img2img"` in the request body.

### Director Reference (Precise Reference) Parameters

5 parallel arrays in the `parameters` object:

| Parameter | Type | Description |
|---|---|---|
| `director_reference_images` | string[] | Base64-encoded processed reference images |
| `director_reference_descriptions` | object[] | Caption objects with type info (see below) |
| `director_reference_strength_values` | double[] | Strength per reference (0.0-1.0) |
| `director_reference_secondary_strength_values` | double[] | Fidelity inversion: `1.0 - fidelity` |
| `director_reference_information_extracted` | double[] | Info extraction amount (always 1.0) |

**Description object format:**
```json
{
  "caption": {
    "base_caption": "character | style | character&style",
    "char_captions": []
  },
  "legacy_uc": false
}
```

Reference types: `character`, `style`, `character&style`

### Vibe Transfer (Reference Image) Parameters

3 parallel arrays in the `parameters` object:

| Parameter | Type | Description |
|---|---|---|
| `reference_image_multiple` | string[] | Base64-encoded processed reference images |
| `reference_strength_multiple` | double[] | Strength per vibe (0.0-1.0, default 0.6) |
| `reference_information_extracted_multiple` | double[] | Info extraction per vibe (0.0-1.0, default 1.0) |

No type system or captions — simpler than Director Reference.

## Response Format

The API returns a **ZIP archive** containing one PNG file.

```
Content-Type: application/x-zip-compressed
```

### Processing:
1. Receive response as raw bytes
2. Decompress ZIP archive
3. Extract first file entry
4. Result is the generated PNG image as `Uint8List`

## Example Payloads

### Basic Text-to-Image
```json
{
  "input": "best quality, amazing quality, 1girl, solo, portrait",
  "model": "nai-diffusion-4-5-full",
  "action": "generate",
  "parameters": {
    "params_version": 3,
    "width": 832,
    "height": 1216,
    "scale": 6.0,
    "sampler": "k_euler_ancestral",
    "steps": 28,
    "seed": 42,
    "n_samples": 1,
    "noise_schedule": "karras",
    "sm": false,
    "sm_dyn": false,
    "dynamic_thresholding": false,
    "uc": "lowres, {bad}, error, worst quality",
    "v4_prompt": {
      "caption": {
        "base_caption": "best quality, amazing quality, 1girl, solo, portrait",
        "char_captions": []
      },
      "use_coords": false,
      "use_order": true
    },
    "v4_negative_prompt": {
      "caption": {
        "base_caption": "lowres, {bad}, error, worst quality",
        "char_captions": []
      }
    }
  }
}
```

### Multi-Character with Interactions
```json
{
  "input": "2girls, outdoor, park",
  "model": "nai-diffusion-4-5-full",
  "action": "generate",
  "parameters": {
    "params_version": 3,
    "width": 1216,
    "height": 832,
    "scale": 6.0,
    "sampler": "k_euler_ancestral",
    "steps": 28,
    "seed": 42,
    "n_samples": 1,
    "noise_schedule": "karras",
    "uc": "lowres",
    "v4_prompt": {
      "caption": {
        "base_caption": "2girls, outdoor, park",
        "char_captions": [
          {
            "char_caption": "source#holding_hands, blonde hair, blue eyes",
            "centers": [{"x": 0.3, "y": 0.5}]
          },
          {
            "char_caption": "target#holding_hands, black hair, red eyes",
            "centers": [{"x": 0.7, "y": 0.5}]
          }
        ]
      },
      "use_coords": true,
      "use_order": true
    },
    "v4_negative_prompt": {
      "caption": {
        "base_caption": "lowres",
        "char_captions": [
          {"char_caption": "lowres", "centers": [{"x": 0.5, "y": 0.5}]},
          {"char_caption": "lowres", "centers": [{"x": 0.5, "y": 0.5}]}
        ]
      }
    }
  }
}
```

### With Director Reference + Vibe Transfer
```json
{
  "parameters": {
    "...": "...core params...",
    "director_reference_images": ["<base64>"],
    "director_reference_descriptions": [
      {
        "caption": {"base_caption": "character", "char_captions": []},
        "legacy_uc": false
      }
    ],
    "director_reference_strength_values": [0.6],
    "director_reference_secondary_strength_values": [0.5],
    "director_reference_information_extracted": [1.0],
    "reference_image_multiple": ["<base64>"],
    "reference_strength_multiple": [0.6],
    "reference_information_extracted_multiple": [1.0]
  }
}
```

### Img2Img
```json
{
  "input": "1girl, detailed background",
  "model": "nai-diffusion-4-5-full",
  "action": "img2img",
  "parameters": {
    "...": "...core params...",
    "image": "<base64 source image>",
    "strength": 0.7,
    "noise": 0.0,
    "extra_noise_seed": 42,
    "add_original_image": true
  }
}
```

## Available Samplers
- `k_euler_ancestral`
- `k_euler`
- `k_lms`
- `pndm`
- `ddim`
- `k_dpmpp_2s_ancestral`
- `k_dpmpp_2m`
- `k_dpmpp_sde`

## Error Responses

| Status | Meaning |
|---|---|
| 200 | Success — ZIP archive with generated PNG |
| 400 | Bad request — invalid parameters |
| 401 | Unauthorized — invalid or expired API key |
| 422 | Unprocessable entity — payload validation error |
| 429 | Rate limited |
| 500 | Server error |

---

## Director Tools API

NovelAI provides image transformation tools via a separate endpoint. These tools operate on existing images rather than generating from text prompts.

**Endpoint:** `POST https://image.novelai.net/ai/augment-image`

**Headers:**
| Header | Value |
|---|---|
| `Authorization` | `Bearer <API_KEY>` |
| `Content-Type` | `application/json` |

### Available Tools

| Tool (`req_type`) | Description |
|---|---|
| `bg-removal` | Remove background from an image, isolating the subject |
| `lineart` | Extract clean line art from an image |
| `sketch` | Convert an image to sketch-style rendering |
| `colorize` | Add color to grayscale or line art images (supports `defry` and `prompt`) |
| `emotion` | Modify character facial expressions (requires `prompt` with mood) |
| `declutter` | Clean up and simplify image compositions |

### Request Format

```json
{
  "req_type": "bg-removal",
  "image": "<base64-encoded source image>",
  "width": 832,
  "height": 1216
}
```

### Tool-Specific Parameters

**Colorize** supports additional parameters:

| Parameter | Type | Description |
|---|---|---|
| `defry` | int (0–5) | Defringe strength — controls how aggressively color bleeding at edges is reduced |
| `prompt` | string | Optional prompt to guide colorization (e.g., "red hair, blue eyes") |

```json
{
  "req_type": "colorize",
  "image": "<base64>",
  "width": 832,
  "height": 1216,
  "defry": 0,
  "prompt": "blonde hair, green eyes"
}
```

**Emotion** requires a mood in the `prompt` field:

| Parameter | Type | Description |
|---|---|---|
| `prompt` | string | Mood keyword from the supported list below |

```json
{
  "req_type": "emotion",
  "image": "<base64>",
  "width": 832,
  "height": 1216,
  "prompt": "happy;;"
}
```

### Supported Emotion Moods (24)

| Mood | Mood | Mood | Mood |
|---|---|---|---|
| neutral | happy | sad | angry |
| scared | surprised | tired | excited |
| nervous | thinking | confused | smug |
| amused | embarrassed | aroused | annoyed |
| proud | panicked | crying | determined |
| shy | disgusted | bored | relieved |

### Response Format

The API returns a **ZIP archive** containing the processed PNG image, identical to the generation endpoint response format.

---

## Planned — Not Yet Implemented in NAIWeaver

The following API capabilities are planned for future integration.

### NAI v4 Vibe File Formats

NovelAI uses proprietary file formats for sharing pre-encoded vibes:

| Format | Description |
|---|---|
| `.naiv4vibe` | Single pre-encoded vibe — contains the encoded representation of a reference image, avoiding re-encoding costs |
| `.naiv4vibeBundle` | Bundle of multiple `.naiv4vibe` files — a collection for sharing complete style sets |

These formats allow sharing vibes between users without requiring access to the original reference images and without re-encoding overhead. Planned integration will add import/export support in the Vibe Transfer manager and the Packs system.
