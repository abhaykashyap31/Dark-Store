package com.darkstore.inventory.repository;

import com.darkstore.inventory.domain.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ProductRepository extends JpaRepository<Product, UUID> {
    boolean existsByCategoryId(UUID categoryId);
    boolean existsBySku(String sku);
    boolean existsBySkuAndIdNot(String sku, UUID id);
}
