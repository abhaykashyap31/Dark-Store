package com.darkstore.cart_order_service.security;

import java.util.UUID;

public record OrderIdentity(UUID userId, String role, UUID storeId) {
}
