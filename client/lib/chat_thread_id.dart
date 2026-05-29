String buildChatThreadId({
  required String itemId,
  required String sellerEmail,
  required String buyerEmail,
}) {
  final normalizedItemId = itemId.trim().toLowerCase();
  final participants = [
    sellerEmail.trim().toLowerCase(),
    buyerEmail.trim().toLowerCase(),
  ]..sort();

  return '${normalizedItemId}__${participants[0]}__${participants[1]}';
}
