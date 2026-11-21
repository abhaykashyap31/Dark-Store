package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "stock_movements")
public class StockMovement {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(name = "store_inventory_id")
    private java.util.UUID storeInventoryId;
    @Column(name = "store_id", nullable = false)
    private java.util.UUID storeId;
    @Column(name = "product_id", nullable = false)
    private java.util.UUID productId;
    @Column(nullable = false)
    private int quantityChange;
    @Column(name = "quantity_delta")
    private int quantityDelta;
    @Column(name = "balance_after")
    private int balanceAfter;
    @Column(name = "type")
    private String type;
    @Column(name = "reference_type")
    private String referenceType;
    @Column(nullable = false)
    private String reason;
    private java.util.UUID referenceId;
    @Column(name = "created_by")
    private java.util.UUID createdBy;
    private Instant createdAt = Instant.now();

    public java.util.UUID getId() { return id; }
    public java.util.UUID getStoreInventoryId() { return storeInventoryId; }
    public void setStoreInventoryId(java.util.UUID storeInventoryId) { this.storeInventoryId = storeInventoryId; }
    public void setId(java.util.UUID id) { this.id = id; }
    public java.util.UUID getStoreId() { return storeId; }
    public void setStoreId(java.util.UUID storeId) { this.storeId = storeId; }
    public java.util.UUID getProductId() { return productId; }
    public void setProductId(java.util.UUID productId) { this.productId = productId; }
    public int getQuantityChange() { return quantityChange; }
    public void setQuantityChange(int quantityChange) { this.quantityChange = quantityChange; }
    public int getQuantityDelta() { return quantityDelta; }
    public void setQuantityDelta(int quantityDelta) { this.quantityDelta = quantityDelta; }
    public int getBalanceAfter() { return balanceAfter; }
    public void setBalanceAfter(int balanceAfter) { this.balanceAfter = balanceAfter; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getReferenceType() { return referenceType; }
    public void setReferenceType(String referenceType) { this.referenceType = referenceType; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public java.util.UUID getReferenceId() { return referenceId; }
    public void setReferenceId(java.util.UUID referenceId) { this.referenceId = referenceId; }
    public java.util.UUID getCreatedBy() { return createdBy; }
    public void setCreatedBy(java.util.UUID createdBy) { this.createdBy = createdBy; }
    public Instant getCreatedAt() { return createdAt; }
}
