package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "reservation_items",
        uniqueConstraints = @UniqueConstraint(columnNames = {"reservation_id", "product_id"}))
public class ReservationItem {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "reservation_id", nullable = false)
    private UUID reservationId;
    @Column(name = "product_id", nullable = false)
    private UUID productId;
    @Column(nullable = false)
    private int quantity;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reservation_id", insertable = false, updatable = false,
            foreignKey = @ForeignKey(name = "fk_reservation_items_reservation"))
    private StockReservation reservation;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id", insertable = false, updatable = false,
            foreignKey = @ForeignKey(name = "fk_reservation_items_product"))
    private Product product;

    public UUID getId() { return id; }
    public UUID getReservationId() { return reservationId; }
    public void setReservationId(UUID reservationId) { this.reservationId = reservationId; }
    public UUID getProductId() { return productId; }
    public void setProductId(UUID productId) { this.productId = productId; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
}
