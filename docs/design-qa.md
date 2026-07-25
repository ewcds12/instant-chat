# Message Composer Design QA

## Comparison Target

- Source visual truth: `/var/folders/s_/6kx28ks54k1d3d09hs7xsngm0000gn/T/codex-clipboard-4f57a544-2f5f-4f88-b85f-60b30bb2cffd.png`
- Implementation capture: `/Users/ewcds/Library/Containers/com.ewcds12.instantchat/Data/tmp/instant-chat-composer-native.png`
- Combined comparison: `/tmp/instant-chat-composer-comparison.png`
- Source pixels: 1594 × 292.
- Implementation pixels: 1556 × 246 at a 2× capture density from a 778 logical-pixel component.
- State: expanded composer containing the same three-line message as the source.

## Full-View Comparison

The implementation matches the source's wide rounded container, top-aligned multiline text, separate bottom action row, left attachment control, and bottom-right circular send control. The implementation intentionally omits the source's model label and microphone because those controls are outside the current product scope.

## Focused Region Comparison

- Typography: the implementation uses the native macOS font at 13 logical pixels and preserves the source's three-line wrapping at the normalized width.
- Spacing: the text starts 12 logical pixels from the expanded container edge, while the bottom actions remain independently aligned.
- Geometry: the 20-pixel corner radius and 28-pixel send control reproduce the source proportions. The send control center follows the outer corner geometry.
- Color: the existing Instant Chat surface, outline, shadow, and primary tokens remain intact instead of introducing a separate ChatGPT palette.
- Copy: the composer hint remains contextual to the selected recipient; no new unsupported labels were added.

## Comparison History

1. The initial implementation kept every control in one row and detected only explicit newline characters. Long visually wrapped text therefore retained an oversized pill shape.
2. The first correction introduced separate collapsed and expanded layouts plus visual-wrap detection. A native component capture showed excessive text inset and an oversized send control.
3. The final correction reduced the expanded text inset, aligned the bottom actions, and matched the source's send-control and corner proportions. The revised combined comparison contains no actionable P0, P1, or P2 mismatch.

## Findings

No actionable P0, P1, or P2 findings remain. The shorter bottom action row is an intentional product constraint caused by omitting the unsupported model and microphone controls.

## Verification

- Shift+Enter inserts a newline without sending.
- Enter sends the message.
- Visually wrapped text switches to the expanded layout without requiring a newline.
- The attachment and send controls move to the bottom action row.
- The composer stops growing after eight lines and scrolls internally.
- Focus remains in the composer after the layout switches.
- The message history snaps to its newest item when the composer height changes.

Final result: passed
