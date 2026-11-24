
package com.darkstore.cart_order_service.dto;

import com.darkstore.cart_order_service.enums.OrderStatus;
import java.time.LocalDateTime;
import java.util.UUID;

public class OrderStatusHistoryResponse {

    private OrderStatus status;
    private UUID changedBy;
    private String remarks;
    private LocalDateTime changedAt;

    public OrderStatusHistoryResponse(
            OrderStatus status,
            UUID changedBy,
            String remarks,
            LocalDateTime changedAt
    ) {
        this.status = status;
        this.changedBy = changedBy;
        this.remarks = remarks;
        this.changedAt = changedAt;
    }

    public OrderStatus getStatus() {
        return status;
    }

    public UUID getChangedBy() {
        return changedBy;
    }

    public String getRemarks() {
        return remarks;
    }

    public LocalDateTime getChangedAt() {
        return changedAt;
    }
}
