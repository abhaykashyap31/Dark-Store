
package com.darkstore.cart_order_service.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class CreateCartRequest {

    @NotNull(message = "User ID is required")
    private UUID userId;

    @NotNull(message = "Store ID is required")
    private UUID storeId;

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public UUID getStoreId() {
        return storeId;
    }

    public void setStoreId(UUID storeId) {
        this.storeId = storeId;
    }
}
