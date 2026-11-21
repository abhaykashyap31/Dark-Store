package com.darkstore.inventory.repository;

import com.darkstore.inventory.domain.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StockMovementRepository extends JpaRepository<StockMovement, UUID> {
    List<StockMovement> findByStoreIdAndProductIdOrderByCreatedAtDesc(UUID storeId, UUID productId);
    boolean existsByProductId(UUID productId);
}
