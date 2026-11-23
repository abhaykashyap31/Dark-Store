
package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.enums.OrderStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class OrderResponse {

    private UUID orderId;
    private UUID userId;
    private OrderStatus status;
    private BigDecimal subtotal;
    private BigDecimal deliveryFee;
    private BigDecimal totalAmount;
    private LocalDateTime createdAt;
    private List<OrderItemResponse> items;

    public OrderResponse(
            UUID orderId,
            UUID userId,
            OrderStatus status,
            BigDecimal subtotal,
            BigDecimal deliveryFee,
            BigDecimal totalAmount,
            LocalDateTime createdAt,
            List<OrderItemResponse> items
    ) {
        this.orderId = orderId;
        this.userId = userId;
        this.status = status;
        this.subtotal = subtotal;
        this.deliveryFee = deliveryFee;
        this.totalAmount = totalAmount;
        this.createdAt = createdAt;
        this.items = items;
    }

    public UUID getOrderId() { return orderId; }
    public UUID getUserId() { return userId; }
    public OrderStatus getStatus() { return status; }
    public BigDecimal getSubtotal() { return subtotal; }
    public BigDecimal getDeliveryFee() { return deliveryFee; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public List<OrderItemResponse> getItems() { return items; }
}
