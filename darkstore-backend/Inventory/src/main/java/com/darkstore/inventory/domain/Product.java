package com.darkstore.inventory.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(nullable = false)
    private String name;
    @Column(columnDefinition = "text")
    private String description;
    private String sku;
    @Column(name = "category_id")
    private java.util.UUID categoryId;
    @Column(name = "image_url")
    private String imageUrl;
    @Column(name = "base_price", precision = 19, scale = 2)
    private BigDecimal basePrice = BigDecimal.ZERO;
    @Column(nullable = false)
    private boolean active = true;
    private java.time.Instant createdAt = java.time.Instant.now();
    private java.time.Instant updatedAt = java.time.Instant.now();

    public java.util.UUID getId() { return id; }
    public void setId(java.util.UUID id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public java.util.UUID getCategoryId() { return categoryId; }
    public void setCategoryId(java.util.UUID categoryId) { this.categoryId = categoryId; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public BigDecimal getBasePrice() { return basePrice; }
    public void setBasePrice(BigDecimal basePrice) { this.basePrice = basePrice; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public java.time.Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(java.time.Instant createdAt) { this.createdAt = createdAt; }
    public java.time.Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(java.time.Instant updatedAt) { this.updatedAt = updatedAt; }
}
