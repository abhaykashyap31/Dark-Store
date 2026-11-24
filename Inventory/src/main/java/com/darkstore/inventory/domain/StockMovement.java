package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "stock_movements")
public class StockMovement {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(name = "store_inventory_id", nullable = false)
    private java.util.UUID storeInventoryId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "store_inventory_id", insertable = false, updatable = false,
            foreignKey = @ForeignKey(name = "fk_stock_movements_inventory"))
    private StoreInventory storeInventory;
    @Column(nullable = false)
    private String type;
    @Column(name = "quantity_delta", nullable = false)
    private int quantityDelta;
    @Column(name = "balance_after", nullable = false)
    private int balanceAfter;
    @Column(name = "reference_type")
    private String referenceType;
    @Column(nullable = false)
    private String reason;
    private java.util.UUID referenceId;
    @Column(name = "performed_by")
    private java.util.UUID performedBy;
    private Instant createdAt = Instant.now();

    public java.util.UUID getId() { return id; }
    public java.util.UUID getStoreInventoryId() { return storeInventoryId; }
    public void setStoreInventoryId(java.util.UUID storeInventoryId) { this.storeInventoryId = storeInventoryId; }
    public void setId(java.util.UUID id) { this.id = id; }
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
    public java.util.UUID getPerformedBy() { return performedBy; }
    public void setPerformedBy(java.util.UUID performedBy) { this.performedBy = performedBy; }
    public Instant getCreatedAt() { return createdAt; }
}
