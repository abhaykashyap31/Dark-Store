package com.darkstore.inventory.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "categories")
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private java.util.UUID id;
    @Column(nullable = false, unique = true)
    private String name;
    @Column(name = "parent_id")
    private java.util.UUID parentId;
    @Column(nullable = false, unique = true)
    private String slug;
    private String description;
    @Column(nullable = false)
    private boolean active = true;
    private java.time.Instant createdAt = java.time.Instant.now();
    private java.time.Instant updatedAt = java.time.Instant.now();

    public java.util.UUID getId() { return id; }
    public void setId(java.util.UUID id) { this.id = id; }
    public java.util.UUID getParentId() { return parentId; }
    public void setParentId(java.util.UUID parentId) { this.parentId = parentId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public java.time.Instant getCreatedAt() { return createdAt; }
    public java.time.Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(java.time.Instant updatedAt) { this.updatedAt = updatedAt; }
}
