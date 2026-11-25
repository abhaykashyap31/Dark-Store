
package com.darkstore.cart_order_service.repository;

import com.darkstore.cart_order_service.entity.RiderAssignment;
import com.darkstore.cart_order_service.enums.AssignmentStatus;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RiderAssignmentRepository
        extends JpaRepository<RiderAssignment, UUID> {

    List<RiderAssignment> findByRiderId(UUID riderId);

    Optional<RiderAssignment> findByOrderId(UUID orderId);

    boolean existsByOrderId(UUID orderId);

    List<RiderAssignment> findByRiderIdAndStatus(
            UUID riderId,
            AssignmentStatus status
    );
}
