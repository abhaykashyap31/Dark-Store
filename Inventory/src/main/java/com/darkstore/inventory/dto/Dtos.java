package com.darkstore.inventory.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public final class Dtos {
    private Dtos() {}

    public record CategoryRequest(
            @NotBlank String name,
            String description,
            UUID parentId,
            boolean active
    ) {
        public CategoryRequest(String name, String description) {
            this(name, description, null, true);
        }
    }

    public record ProductRequest(
            @NotBlank String name,
            String description,
            @NotBlank String sku,
            UUID categoryId,
            String imageUrl,
            @PositiveOrZero BigDecimal basePrice,
            boolean active
    ) {
        public ProductRequest(String name, String description, String sku, UUID categoryId, boolean active) {
            this(name, description, sku, categoryId, null, BigDecimal.ZERO, active);
        }
    }

    public record StockRequest(
            @NotNull UUID storeId,
            @NotNull UUID productId,
            @NotNull BigDecimal price,
            int onHand,
            int lowStockThreshold
    ) {}

    public record StockAdjustment(
            @NotNull UUID storeId,
            @NotNull UUID productId,
            int quantityChange,
            @NotBlank String reason,
            UUID referenceId
    ) {}

    public record ReservationItem(
            @NotNull UUID productId,
            @Positive int quantity
    ) {}

    public record ReserveRequest(
            @NotNull UUID orderId,
            @NotNull UUID storeId,
            @NotNull @NotEmpty List<ReservationItem> items
    ) {}

    public record ReservationItemResult(UUID productId, int quantity, String status, Integer available) {}

    public record ReserveResponse(UUID orderId, String status, List<ReservationItemResult> items) {}

    public record ValidateItem(UUID productId, String name, int available, BigDecimal price) {}

    public record ValidateResponse(UUID storeId, List<ValidateItem> items) {}

    public record ValidateRequest(@NotNull UUID storeId, @NotNull List<UUID> productIds) {}
    public record OrderRequest(@NotNull UUID orderId) {}
}
