
package com.darkstore.cart_order_service.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class CartItemResponse {

    private UUID productId;
    private String productName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;

    public CartItemResponse(
            UUID productId,
            String productName,
            Integer quantity,
            BigDecimal unitPrice
    ) {
        this.productId = productId;
        this.productName = productName;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.totalPrice = unitPrice.multiply(
                BigDecimal.valueOf(quantity)
        );
    }

    public UUID getProductId() {
        return productId;
    }

    public String getProductName() {
        return productName;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public BigDecimal getTotalPrice() {
        return totalPrice;
    }
}
