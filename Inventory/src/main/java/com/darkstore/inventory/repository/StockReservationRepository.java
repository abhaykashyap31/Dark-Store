package com.darkstore.inventory.repository;

import com.darkstore.inventory.domain.StockReservation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface StockReservationRepository extends JpaRepository<StockReservation, UUID> {
    Optional<StockReservation> findByOrderIdAndStoreId(UUID orderId, UUID storeId);
    List<StockReservation> findByOrderId(UUID orderId);
}
