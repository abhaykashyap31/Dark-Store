
package com.darkstore.cart_order_service.repository;

import com.darkstore.cart_order_service.entity.Cart;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface CartRepository extends JpaRepository<Cart, UUID> {

    Optional<Cart> findByUserIdAndStatus(
            UUID userId,
            com.darkstore.cart_order_service.enums.CartStatus status
    );
}
