
package com.darkstore.cart_order_service.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class CartResponse {

    private UUID cartId;
    private UUID userId;
    private UUID storeId;
    private List<CartItemResponse> items;
    private BigDecimal subtotal;

    public CartResponse(
            UUID cartId,
            UUID userId,
            UUID storeId,
            List<CartItemResponse> items,
            BigDecimal subtotal
    ) {
        this.cartId = cartId;
        this.userId = userId;
        this.storeId = storeId;
        this.items = items;
        this.subtotal = subtotal;
    }

    public UUID getCartId() {
        return cartId;
    }

    public UUID getUserId() {
        return userId;
    }

    public UUID getStoreId() {
        return storeId;
    }

    public List<CartItemResponse> getItems() {
        return items;
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }
}
