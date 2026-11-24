package com.darkstore.inventory.repository;

import com.darkstore.inventory.domain.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StockMovementRepository extends JpaRepository<StockMovement, UUID> {
    List<StockMovement> findByStoreInventory_StoreIdAndStoreInventory_ProductIdOrderByCreatedAtDesc(
            UUID storeId, UUID productId);
    boolean existsByStoreInventory_ProductId(UUID productId);
}
