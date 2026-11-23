package com.darkstore.inventory.repository;

import com.darkstore.inventory.domain.StoreInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface StoreInventoryRepository extends JpaRepository<StoreInventory, UUID> {
    Optional<StoreInventory> findByStoreIdAndProductId(UUID storeId, UUID productId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<StoreInventory> findForUpdateByStoreIdAndProductId(UUID storeId, UUID productId);
    List<StoreInventory> findByStoreId(UUID storeId);
    boolean existsByProductId(UUID productId);
}
