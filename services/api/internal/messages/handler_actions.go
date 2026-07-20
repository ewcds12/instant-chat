package messages

import (
	"net/http"
)

// Recall removes a recent message for every conversation member.
func (h *Handler) Recall(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	messageID, ok := positivePathID(w, r, "message_id", "Message ID")
	if !ok {
		return
	}
	if err := h.service.Recall(r.Context(), currentUserID(r), conversationID, messageID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// Delete hides a message only from the current conversation member.
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	messageID, ok := positivePathID(w, r, "message_id", "Message ID")
	if !ok {
		return
	}
	if err := h.service.Delete(r.Context(), currentUserID(r), conversationID, messageID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
