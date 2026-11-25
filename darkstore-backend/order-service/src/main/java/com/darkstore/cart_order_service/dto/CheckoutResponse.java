
package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.enums.OrderStatus;

import java.math.BigDecimal;
import java.util.UUID;

public class CheckoutResponse {

    private UUID orderId;
    private OrderStatus status;
    private BigDecimal subtotal;
    private BigDecimal deliveryFee;
    private BigDecimal totalAmount;

    public CheckoutResponse(
            UUID orderId,
            OrderStatus status,
            BigDecimal subtotal,
            BigDecimal deliveryFee,
            BigDecimal totalAmount
    ) {
        this.orderId = orderId;
        this.status = status;
        this.subtotal = subtotal;
        this.deliveryFee = deliveryFee;
        this.totalAmount = totalAmount;
    }

    public UUID getOrderId() {
        return orderId;
    }

    public OrderStatus getStatus() {
        return status;
    }

    public BigDecimal getSubtotal() {
        return subtotal;
    }

    public BigDecimal getDeliveryFee() {
        return deliveryFee;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }
}
