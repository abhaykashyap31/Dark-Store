
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Cart;
import com.darkstore.cart_order_service.entity.CartItem;

import com.darkstore.cart_order_service.enums.CartStatus;

import com.darkstore.cart_order_service.repository.CartRepository;
import com.darkstore.cart_order_service.repository.CartItemRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;
import java.math.BigDecimal;

@Service
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;

    // Constructor injection
    public CartService(
            CartRepository cartRepository,
            CartItemRepository cartItemRepository
    ) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
    }

    // 1. Create a cart
    @Transactional
    public Cart createCart(UUID userId, UUID storeId) {

        // Check whether customer already has an active cart
        Optional<Cart> existingCart =
                cartRepository.findByUserIdAndStatus(
                        userId, CartStatus.ACTIVE
                );

        if (existingCart.isPresent()) {

            Cart cart = existingCart.get();

            // Check whether the existing cart belongs to the same store
            if (!cart.getStoreId().equals(storeId)) {
                throw new IllegalStateException(
                        "An active cart already exists for another store"
                );
            }

            return cart;
        }

        // Create a new cart
        Cart newCart = new Cart();

        newCart.setUserId(userId);
        newCart.setStoreId(storeId);
        newCart.setStatus(CartStatus.ACTIVE);

        return cartRepository.save(newCart);
    }

    // 2. Get customer's active cart
    @Transactional(readOnly = true)
    public Cart getActiveCart(UUID userId) {

        return cartRepository.findByUserIdAndStatus(
                userId, CartStatus.ACTIVE
        ).orElseThrow(() ->
                new IllegalArgumentException(
                        "Active cart not found"
                )
        );
    }

    // 3. Add product to cart
    @Transactional
    public CartItem addProductToCart(
            UUID userId,
            UUID productId,
            String productName,
            Integer quantity,
            BigDecimal unitPrice
    ) {

        // Validate quantity
        if (quantity == null || quantity <= 0) {
            throw new IllegalArgumentException(
                    "Quantity must be greater than zero"
            );
        }

        // Get customer's active cart
        Cart cart = getActiveCart(userId);

        // Check whether product already exists in cart
        Optional<CartItem> existingItem =
                cartItemRepository.findByCartIdAndProductId(
                        cart.getId(), productId
                );

        if (existingItem.isPresent()) {

            // Increase existing product quantity
            CartItem item = existingItem.get();

            item.setQuantity(item.getQuantity() + quantity);

            return cartItemRepository.save(item);
        }

        // Create a new cart item
        CartItem newItem = new CartItem();

        newItem.setCart(cart);
        newItem.setProductId(productId);
        newItem.setProductName(productName);
        newItem.setQuantity(quantity);
        newItem.setUnitPrice(unitPrice);

        return cartItemRepository.save(newItem);
    }



    @Transactional
    public CartItem updateProductQuantity(
            UUID userId,
            UUID productId,
            Integer quantity
    ) {
        if (quantity == null || quantity <= 0) {
            throw new IllegalArgumentException(
                    "Quantity must be greater than zero"
            );
        }

        Cart cart = getActiveCart(userId);

        CartItem item = cartItemRepository
                .findByCartIdAndProductId(cart.getId(), productId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Product not found in cart"
                        )
                );

        item.setQuantity(quantity);

        return cartItemRepository.save(item);
    }

    @Transactional
    public void removeProduct(
            UUID userId,
            UUID productId
    ) {
        Cart cart = getActiveCart(userId);

        CartItem item = cartItemRepository
                .findByCartIdAndProductId(cart.getId(), productId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Product not found in cart"
                        )
                );

        cartItemRepository.delete(item);
    }

}
