package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "store_inventory",
        uniqueConstraints = @UniqueConstraint(columnNames = {"store_id", "product_id"}))
public class StoreInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(name = "store_id", nullable = false)
    private java.util.UUID storeId;
    @Column(name = "product_id", nullable = false)
    private java.util.UUID productId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id", insertable = false, updatable = false,
            foreignKey = @ForeignKey(name = "fk_store_inventory_product"))
    private Product product;
    @Column(name = "quantity_on_hand", nullable = false)
    private int onHand = 0;
    @Column(name = "reserved_quantity", nullable = false)
    private int reserved = 0;
    @Column(name = "low_stock_threshold", nullable = false)
    private int lowStockThreshold = 0;
    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;
    @Version
    private long version;
    private Instant updatedAt = Instant.now();

    public int getAvailable() { return onHand - reserved; }
    public long getVersion() { return version; }
    public java.util.UUID getId() { return id; }
    public void setId(java.util.UUID id) { this.id = id; }
    public java.util.UUID getStoreId() { return storeId; }
    public void setStoreId(java.util.UUID storeId) { this.storeId = storeId; }
    public java.util.UUID getProductId() { return productId; }
    public void setProductId(java.util.UUID productId) { this.productId = productId; }
    public int getOnHand() { return onHand; }
    public void setOnHand(int onHand) { this.onHand = onHand; }
    public int getReserved() { return reserved; }
    public void setReserved(int reserved) { this.reserved = reserved; }
    public int getLowStockThreshold() { return lowStockThreshold; }
    public void setLowStockThreshold(int lowStockThreshold) { this.lowStockThreshold = lowStockThreshold; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
