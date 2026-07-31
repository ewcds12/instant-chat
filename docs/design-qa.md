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

# Contact Info Redesign Design QA

## Comparison Target

- Selected Product Design visual: `/Users/ewcds/.codex/generated_images/019fb7bb-097b-7e61-a06b-1f260f8cc2ca/exec-bc1b3439-31c4-4b60-b4ca-ef945423afa8.png`
- Native macOS implementation capture: `/tmp/instant-chat-contact-info-implementation.jpeg`
- Combined comparison: `/tmp/instant-chat-contact-info-comparison.png`
- Density refinement source: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-94116f6f-f7a9-4bf2-8293-486a802ac8e3.png`
- Compact native capture: `/tmp/instant-chat-contact-info-compact-implementation.png`
- Density comparison: `/tmp/instant-chat-contact-info-density-comparison.png`
- Selected visual pixels: 1,227 × 1,282.
- Native verification viewport: 1,150 × 722.
- Density verification state: Lamine Yamal selected with account ID 16, three shared images, two files, and one link group.

## Visual Comparison

- The contact column now follows the selected visual's hierarchy: a compact `Contact Info` toolbar, horizontal avatar and identity row, right-aligned Message action, and top-aligned Shared section.
- The implementation retains the product's existing 180-point app sidebar and 280-point contact directory instead of turning the selected standalone detail concept into a new navigation surface.
- The avatar, button, surface, outline, type, corner, spacing, and blue-accent treatments use existing Instant Chat theme tokens.
- Up to three real shared images occupy equal media slots. The verified account currently has one image, so the remaining width is intentionally left open instead of displaying generated or placeholder media.
- Missing file and link categories use subdued, explicit empty rows that preserve the selected layout without inventing content.
- The detail column scrolls independently at the existing 1,150 × 722 development viewport, keeping the toolbar and app navigation stable while exposing the complete Shared section.

### Compact Density Refinement

- The detail header is 56 points tall, the identity block is 112 points, and the avatar radius is 38 points, preserving hierarchy while removing excess vertical mass.
- The Message action is 36 points tall with a 16-point icon. The internal account ID is intentionally omitted because it is not useful in the contact-facing experience.
- Shared thumbnails are capped at 164-point squares with 12-point gaps. File and link rows are 54 points tall with smaller icons and type that still follows the existing theme scale.
- Horizontal content insets are 24 points and vertical insets are 18 points. The full Shared group now fits comfortably in the 722-point verification viewport without changing navigation or contact-list density.

## Interaction Verification

- Message and See All select the existing direct conversation and switch to Chats without creating a conversation.
- Selecting a real shared image opens the authenticated multi-image preview, including its existing download action.
- Selecting a shared file uses the existing native download choice and Save dialog.
- Selecting Links opens a list of real `http` or `https` URLs parsed from message history; choosing one opens it through macOS.
- Recalled messages are excluded, repeated attachment IDs and URLs are deduplicated, and shared content failure and no-content states are explicit.
- The two-second conversation recovery cycle preserves the current Shared layout and reloads it only when the selected conversation's latest message changes.

## Findings

- Resolved P1: the previous identity-only center state left most of the detail column unused and repeated the selected contact in the toolbar.
- Resolved P1: the concept's example media and documents were replaced with authenticated conversation data so the screen never implies files that do not exist.
- Resolved P2: accounts with only one content category now retain the intended grouped structure through accurate empty file and link rows.
- Resolved P1: periodic conversation recovery previously reloaded Shared content and briefly replaced it with a shorter loading state, which made the detail page visibly jump.
- Resolved P1: the first complete Contact Info implementation used oversized identity, media, button, and row metrics that made the desktop panel feel coarse and pushed useful content below the fold.
- Resolved P2: proportional compaction now keeps identity, account metadata, three media previews, two file rows, and the link group visible together without clipping, crowding, or weakening the primary action.
- No actionable P0, P1, or P2 visual, interaction, or accessibility findings remain after the combined native comparison.

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
