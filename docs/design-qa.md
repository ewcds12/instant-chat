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
- Up to three pasted images remain staged in paste order; a fourth is rejected with visible feedback and its temporary file is released.
- Each remove control clears only its associated image draft and preserves the other images and typed text.
- One send action uploads every staged image in order and then sends non-empty text.
- Successful upload, removal, conversation change, page disposal, limit rejection, and inactive async completion release app-owned temporary files.
- The existing 15 MB image upload validation remains authoritative.

## Findings

No actionable P0, P1, or P2 visual or interaction findings remain. Image and text persist as two ordered messages because the current API models one message kind per record; the composer does not imply an unsupported compound-message contract.

Final result: passed

---

# Contacts Friend Request Drawer Design QA

## Comparison Target

- Source visual truth: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-e303e2a9-d595-4ee0-88fb-5322c0ca03a6.png`
- Refinement evidence: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-5c5be47e-bf3b-4844-9baf-b18b1c2dfe19.png`
- Native macOS implementation capture: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/com.openai.sky.CUAService/Instant Chat Screenshot 2026-07-26 at 9.43.57 PM.jpeg`
- Focused before-and-after comparison: `/tmp/instant-chat-friend-request-refinement-comparison.png`
- Verification viewport: 1,150 × 722.
- State: one incoming friend request with the inline drawer expanded.

## Visual Comparison

- The disclosure card appears immediately below the existing Contacts search field and does not change the sidebar, directory, or detail-column widths.
- Per the final product direction, the header contains only the friend-request label, a fixed 20-point circular count badge, and one trailing disclosure control; requester avatars are not repeated in the header.
- Each expanded row shows a slightly emphasized display name, the requester's ID, Decline, Accept, and an aligned inset separator; requester avatars are omitted.
- The Decline action uses a neutral macOS-style bordered treatment while Accept remains the only primary action; both controls have balanced horizontal padding and an 8-point separation.
- The implementation uses the existing macOS glass surface, outline, primary color, typography, compact control tokens, and a 12-point card radius.
- Density is reduced proportionally from the wider source mockup so the complete interaction fits the existing 280-point Contacts directory without changing the application layout.

## Interaction Verification

- The drawer is omitted when there are no incoming requests.
- Clicking the summary card expands and collapses the request list with a 180 ms native-feeling size and disclosure rotation animation.
- Three rows remain visible; additional requests scroll inside the drawer instead of displacing the entire Contacts directory.
- Decline immediately removes only the selected request and updates the singular or plural count.
- Accept refreshes contacts, removes the request, and selects the newly accepted contact.
- Re-selecting Contacts still performs the existing silent refresh, so the drawer receives current request data without restoring a refresh button.
- Requests no longer appears as a standalone sidebar workspace.

## Findings

- Resolved P1: the header previously repeated requester avatars and displayed two disclosure icons.
- Resolved P1: the count badge inherited loose constraints and could stretch vertically.
- Resolved P2: row actions were visually cramped and the Decline action competed with Accept for emphasis.
- No actionable P0, P1, or P2 visual, interaction, or accessibility findings remain after native comparison.

Final result: passed
