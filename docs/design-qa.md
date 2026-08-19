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

# Contact Message History Search Design QA

## Comparison Target

- Selected Product Design visual: `/Users/ewcds/.codex/visualizations/2026/07/31/019fb7bb-097b-7e61-a06b-1f260f8cc2ca/history-search-sheet.png`
- Native macOS implementation capture: `/tmp/instant-chat-contact-history-search-final.png`
- Full-view comparison: `/tmp/instant-chat-contact-history-search-comparison.png`
- Focused modal comparison: `/tmp/instant-chat-contact-history-search-focused-comparison.png`
- Older target-message navigation capture: `/tmp/instant-chat-message-target-older.png`
- Native verification viewport: 1,150 × 722.
- Verification state: Kylian Mbappé selected with the query `https` and two matching real messages. The source uses Antoine and six illustrative results, so content volume differs while the interaction and layout remain equivalent.

## Visual Comparison

- The implementation preserves the selected focused-sheet composition, approximately two-thirds of the detail-column width, with a dimmed Contact Info workspace behind it.
- Title, Cancel action, focused search field, result count, bordered results surface, compact sender and timestamp metadata, trailing Open actions, and the Return-key hint follow the selected hierarchy.
- The search icon, clear icon, typography, colors, outline, corner radius, focus treatment, and spacing use the existing Instant Chat macOS theme rather than introducing a parallel visual system.
- The result surface intentionally retains open space when the real query has only two matches. It does not fabricate messages to fill the selected visual's six-row example.
- Both the complete window and focused modal were normalized and inspected side by side at the same visible scale.

## Interaction Verification

- Opening the header search action presents the sheet immediately and focuses the query field.
- The same focused complete-history search is available from the Chats conversation header and uses the selected Contact Info layout and result behavior unchanged.
- The dialog loads every cursor-paginated message page through the existing authenticated gateway, excludes recalled messages, matches body text case-insensitively, and sorts matches newest first.
- Clearing the field restores the initial guidance, failures provide a retry action, and no-match states remain explicit.
- Clicking Open or a result row closes the sheet, switches to Chats, selects the existing direct conversation, loads older pages until the target is present, scrolls it into view, and applies a three-second highlight without moving the retained history position when the highlight clears.
- Pressing Return opens the first visible result, matching the footer instruction.
- Native verification confirmed the complete Contact Info → search → result → highlighted chat-message path without sending or changing any message.

## Findings

- Resolved P2: the initial implementation omitted the selected visual's keyboard hint even though Return already opened the first result.
- No actionable P0, P1, or P2 visual, interaction, or accessibility findings remain after the normalized full-view and focused comparisons.

### Chats Entry Consistency

- Contact Info source capture: `/tmp/instant-chat-contact-history-search-final.png`.
- Chats implementation capture: `/tmp/instant-chat-chats-history-search.png`.
- Full-window comparison: `/tmp/instant-chat-chats-history-search-comparison.png`.
- Focused modal comparison: `/tmp/instant-chat-chats-history-search-focused-comparison.png`.
- Result-navigation capture: `/tmp/instant-chat-chats-search-target.jpeg`.
- Both captures are 1,150 × 722 pixels and were compared at 1:1 scale without density normalization.
- The source state searches Kylian Mbappé's history for `https`; the Chats state searches Cristiano Ronaldo's history for `What`. These real-data differences intentionally change only participant copy, result count, timestamps, and message bodies.
- Typography, spacing and layout, colors and tokens, assets and icons, and fixed interface copy match because both entry points render the same history-search component.
- Native verification confirmed that the Chats header opens the complete cursor-paginated history search and that selecting a result closes the sheet, retains the loaded history position, and uses the same three-second target highlight.
- No actionable P0, P1, or P2 visual, interaction, or accessibility findings remain in the Chats entry comparison.

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

---

# Explore Design QA (Superseded Right Rail)

Status: historical. The discovery rail, its search field, popular-post cards,
and people suggestions were intentionally removed from the current Explore
layout. The evidence below documents the earlier implementation only.

## Evidence

- Source visual truth: `/Users/ewcds/.codex/generated_images/019fb7bb-097b-7e61-a06b-1f260f8cc2ca/exec-655d77e1-67f0-4786-b0ba-f0c585a89af3.png`
- Implementation screenshot: `/tmp/instant_chat_explore_qa/implementation.png`
- Combined comparison: `/tmp/instant_chat_explore_qa/comparison.png`
- Source pixels: `1553 × 1013`
- Implementation pixels: `1150 × 750`
- Comparison viewport: macOS main window at `1150 × 750` logical pixels and `1×` capture density
- Normalization: the source was resized to `1150 × 750` before the side-by-side comparison because both artifacts use the same aspect ratio.
- State: authenticated Explore page, For you selected, populated feed, default window size.

## Full-View Comparison

The implementation matches the source hierarchy: existing app sidebar, Explore title and centered feed tabs, compact inline composer, continuous divided post feed, fixed right discovery rail, search, popular content, and people suggestions. The main-feed and discovery-rail proportions remain balanced at the app's default window size.

## Focused Comparison

A separate crop was not required because the normalized `1150 × 750` comparison keeps the header, composer, feed rows, search field, rail cards, type hierarchy, borders, and spacing readable in one view. The header/tab alignment and both right-rail cards were inspected at original implementation resolution.

## Findings

- No actionable P0, P1, or P2 differences remain.
- Accepted dynamic-content difference: production posts supply the author avatars, text, and imagery, so the preview content does not reproduce the generated mock's fictional assets.
- Accepted product-model difference: engagement totals and polls are not rendered because the current post contract does not expose those fields. The action rhythm is preserved without inventing server data.
- Accepted existing-product behavior: Refresh and Explore settings remain in the header beside the compose action.

## Comparison History

1. Initial default-window capture hid the discovery rail because the responsive breakpoint exceeded the available content width.
2. The breakpoint was reduced from `980` to `900` logical pixels.
3. The post-fix capture shows the search, Popular today, and People you may know sections at the default `1150 × 750` window size without compressing or clipping the feed.

## Interaction Verification

- For you and Contacts tabs respond and update the feed filter.
- Search filters by post text, display name, and username.
- Composer surface and Post button open the existing post composer.
- Author discovery rows apply an author search to the feed.
- Like and bookmark controls expose selected and unselected states.
- Existing refresh, report, and delete actions remain available.

## Follow-Up Polish

- P3: Add real engagement counts and poll rendering only after the server contract supports them.

## Final Result

final result: passed

---

# Settings Window Shell Design QA

## Evidence

- Source visual truth: `/Users/ewcds/.codex/generated_images/019fb7bb-097b-7e61-a06b-1f260f8cc2ca/exec-d8379690-8841-4bae-8eec-c43488a7af89.png`
- Native implementation capture: `/tmp/settings-window-general-native.jpeg`
- Side-by-side comparison: `/tmp/settings-window-design-qa.png`
- Source pixels: `1508 × 1043`
- Native capture pixels: `760 × 500`
- Window target: `920 × 620` logical pixels, with a `760 × 500` minimum size.
- State: standalone macOS Settings window, General selected, authenticated app window retained behind it.

## Full-View Comparison

The implementation preserves the selected direction's compact two-column macOS settings layout: native traffic lights, a narrow category sidebar with search, six clearly grouped categories, and a spacious settings surface on the right. General exposes representative switches and value rows so spacing, hierarchy, and control density can be judged before individual features are connected.

## Focused Comparison

- Typography: heading, row labels, secondary values, and sidebar labels follow the app's existing type hierarchy and remain legible at minimum window size.
- Spacing and layout: sidebar width, row rhythm, dividers, and right-aligned controls match the source structure without overflow.
- Colors and tokens: the existing Instant Chat blue, neutral surfaces, subtle dividers, and selected-row tint are reused consistently.
- Icons: built-in Material symbols provide a coherent category set without introducing mixed raster assets.
- Copy: category names and General row labels match the approved visual direction.

## Interaction Verification

- The existing sidebar gear opens a reusable, genuinely separate macOS window.
- Category selection switches the right-side shell between all six sections.
- Sidebar search filters categories without changing the main app state.
- Closing Settings leaves the primary Instant Chat window running.
- General controls are intentionally local preview state; persistence and platform behavior will be connected as each settings feature is implemented.

## Findings

- No actionable P0, P1, or P2 visual, interaction, overflow, or accessibility findings remain.
- P3, accepted by scope: Appearance, Messages, Notifications, Privacy, and Storage currently show compact placeholders because the user requested the shell first and feature implementation later.

## Final Result

final result: passed

---

# Explore Multi-Image Layout Design QA

## Evidence

- Two-image source: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-fc0bb9a0-14fa-43fb-9021-9ccbe21dfe46.png`
- Three-image source: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-8d10f576-867d-4565-999b-ea69ce4c9c3b.png`
- Four-image source: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-1b33e395-d82c-4460-b259-5f0881996c17.png`
- Native two-image capture: `/tmp/explore-two-layout.jpeg`
- Native three-image capture: `/tmp/explore-three-layout.jpeg`
- Native four-image capture: `/tmp/explore-four-layout.jpeg`
- Verification viewport: macOS main window at `1150 × 750` logical pixels.

## Visual Comparison

- Two images use equal-width side-by-side tiles inside one rounded frame.
- Three images use one full-height left tile with two equal stacked tiles on the right.
- Four images use an even `2 × 2` mosaic.
- Every mosaic uses one shared outer corner radius, a subtle outline, and two-point internal separators.
- Multi-image tiles intentionally use cover cropping like the references; selecting any tile still opens the existing full-image viewer.

## Verification

- Native captures confirmed the two-, three-, and four-image layouts with real Explore post data.
- Geometry tests verify tile alignment, row and column spans, gaps, and the two distinct multi-image heights.
- No actionable P0, P1, or P2 visual or interaction findings remain.

## Final Result

final result: passed
