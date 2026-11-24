
package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Cart;
import com.darkstore.cart_order_service.entity.CartItem;

import com.darkstore.cart_order_service.enums.CartStatus;

import com.darkstore.cart_order_service.repository.CartRepository;
import com.darkstore.cart_order_service.repository.CartItemRepository;
import com.darkstore.cart_order_service.integration.InventoryClient;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final InventoryClient inventoryClient;

    public CartService(
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            InventoryClient inventoryClient
    ) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.inventoryClient = inventoryClient;
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
            Integer quantity
    ) {

        // Validate quantity
        if (quantity == null || quantity <= 0) {
            throw new IllegalArgumentException(
                    "Quantity must be greater than zero"
            );
        }

        // Get customer's active cart
        Cart cart = getActiveCart(userId);

        InventoryClient.AvailableProduct product = getAvailableProduct(cart.getStoreId(), productId);

        // Check whether product already exists in cart
        Optional<CartItem> existingItem =
                cartItemRepository.findByCartIdAndProductId(
                        cart.getId(), productId
                );

        if (existingItem.isPresent()) {

            // Increase existing product quantity
            CartItem item = existingItem.get();
            int updatedQuantity = item.getQuantity() + quantity;
            ensureAvailable(product, updatedQuantity);

            item.setQuantity(updatedQuantity);
            item.setProductName(product.name());
            item.setUnitPrice(product.price());

            return cartItemRepository.save(item);
        }

        ensureAvailable(product, quantity);

        // Create a new cart item
        CartItem newItem = new CartItem();

        newItem.setCart(cart);
        newItem.setProductId(productId);
        newItem.setProductName(product.name());
        newItem.setQuantity(quantity);
        newItem.setUnitPrice(product.price());

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

        InventoryClient.AvailableProduct product = getAvailableProduct(cart.getStoreId(), productId);
        ensureAvailable(product, quantity);
        item.setQuantity(quantity);
        item.setProductName(product.name());
        item.setUnitPrice(product.price());

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

    private InventoryClient.AvailableProduct getAvailableProduct(UUID storeId, UUID productId) {
        return inventoryClient.validateProducts(storeId, List.of(productId)).stream()
                .filter(product -> product.productId().equals(productId))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException(
                        "Inventory did not return product " + productId));
    }

    private void ensureAvailable(InventoryClient.AvailableProduct product, int requestedQuantity) {
        if (product.available() < requestedQuantity) {
            throw new IllegalStateException(
                    "Insufficient stock for product " + product.productId()
                            + "; available=" + product.available());
        }
    }

}
