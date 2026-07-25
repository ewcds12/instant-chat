# Clipboard Image Composer Design QA

## Comparison Target

- Source visual truth: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-4eec9eca-3d8f-4772-b1c5-cc164e67206f.png`
- Implementation capture: `/tmp/instant-chat-pasted-image-draft.jpeg`
- Combined comparison: `/tmp/instant-chat-paste-comparison.png`
- Source pixels: 1,536 × 428.
- Implementation window pixels: 1,150 × 722.
- State: one clipboard image and `Hello guys` staged in the selected conversation.

## Full-View Comparison

The implementation preserves the existing Instant Chat composer shell and follows the source hierarchy: image preview first, text directly below it, and an independent bottom action row. The attachment control remains at bottom left and the send control remains at bottom right as the composer expands.

## Focused Region Comparison

- The preview is a square, cover-cropped image with the same corner treatment as the product's existing media surfaces.
- The remove control overlaps the preview's top-right corner and uses a dark translucent circular surface with a white close icon.
- Text remains left aligned below the preview and retains keyboard focus while the composer changes height.
- The composer uses existing macOS surface, outline, shadow, type, and primary-color tokens.
- The source's model label and microphone are intentionally absent because Instant Chat does not provide those functions.

The source screenshot itself was used as the clipboard payload during native verification. Its mostly white center therefore appears mostly white when cover-cropped into the preview; this confirms the real clipboard bytes are rendered rather than substituted with a mock asset.

## Interaction Verification

- Native macOS Command+V and the Edit > Paste command detect clipboard bitmap data before text paste.
- Plain-text clipboard content continues through the standard composer paste path.
- A second pasted image replaces the first staged image and releases the earlier temporary file.
- The remove control clears only the image draft and preserves typed text.
- One send action uploads the image first and then sends non-empty text.
- Successful upload, removal, replacement, conversation disposal, and inactive async completion release app-owned temporary files.
- The existing 15 MB image upload validation remains authoritative.

## Findings

No actionable P0, P1, or P2 visual or interaction findings remain. Image and text persist as two ordered messages because the current API models one message kind per record; the composer does not imply an unsupported compound-message contract.

Final result: passed
