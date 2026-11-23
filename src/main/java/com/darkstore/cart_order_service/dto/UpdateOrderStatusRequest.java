
package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.enums.OrderStatus;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public class UpdateOrderStatusRequest {

    @NotNull(message = "Order status is required")
    private OrderStatus status;

    @NotNull(message = "Changed by user ID is required")
    private UUID changedBy;

    public OrderStatus getStatus() {
        return status;
    }

    public void setStatus(OrderStatus status) {
        this.status = status;
    }

    public UUID getChangedBy() {
        return changedBy;
    }

    public void setChangedBy(UUID changedBy) {
        this.changedBy = changedBy;
    }
}

