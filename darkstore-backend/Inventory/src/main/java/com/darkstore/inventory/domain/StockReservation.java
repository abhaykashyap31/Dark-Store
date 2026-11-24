package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "reservations",
        uniqueConstraints = @UniqueConstraint(columnNames = {"order_id", "store_id", "product_id"}))
public class StockReservation {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(name = "order_id", nullable = false)
    private java.util.UUID orderId;
    @Column(name = "store_id", nullable = false)
    private java.util.UUID storeId;
    @Column(name = "product_id", nullable = false)
    private java.util.UUID productId;
    @Column(nullable = false)
    private int quantity;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReservationStatus status = ReservationStatus.RESERVED;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    public java.util.UUID getId() { return id; }
    public void setId(java.util.UUID id) { this.id = id; }
    public java.util.UUID getOrderId() { return orderId; }
    public void setOrderId(java.util.UUID orderId) { this.orderId = orderId; }
    public java.util.UUID getStoreId() { return storeId; }
    public void setStoreId(java.util.UUID storeId) { this.storeId = storeId; }
    public java.util.UUID getProductId() { return productId; }
    public void setProductId(java.util.UUID productId) { this.productId = productId; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public ReservationStatus getStatus() { return status; }
    public void setStatus(ReservationStatus status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public enum ReservationStatus { RESERVED, CONFIRMED, RELEASED }
}
