
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.*;
import com.darkstore.cart_order_service.entity.Cart;
import com.darkstore.cart_order_service.entity.CartItem;
import com.darkstore.cart_order_service.repository.CartItemRepository;
import com.darkstore.cart_order_service.service.CartService;

import jakarta.validation.Valid;

import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/cart")
public class CartController {

    private final CartService cartService;
    private final CartItemRepository cartItemRepository;

    public CartController(
            CartService cartService,
            CartItemRepository cartItemRepository
    ) {
        this.cartService = cartService;
        this.cartItemRepository = cartItemRepository;
    }

    // 1. Create cart
    @PostMapping
    public Cart createCart(
            @Valid @RequestBody CreateCartRequest request
    ) {
        return cartService.createCart(
                request.getUserId(),
                request.getStoreId()
        );
    }

    // 2. Add product to cart
    @PostMapping("/items")
    public CartItemResponse addProduct(
            @RequestHeader("X-USER-ID") UUID userId,
            @Valid @RequestBody AddCartItemRequest request
    ) {
        CartItem item = cartService.addProductToCart(
                userId,
                request.getProductId(),
                request.getProductName(),
                request.getQuantity(),
                request.getUnitPrice()
        );

        return new CartItemResponse(
                item.getProductId(),
                item.getProductName(),
                item.getQuantity(),
                item.getUnitPrice()
        );
    }

    // 3. View active cart
    @GetMapping
    public CartResponse getCart(
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        Cart cart = cartService.getActiveCart(userId);

        List<CartItem> cartItems =
                cartItemRepository.findByCartId(cart.getId());

        List<CartItemResponse> items = cartItems.stream()
                .map(item -> new CartItemResponse(
                        item.getProductId(),
                        item.getProductName(),
                        item.getQuantity(),
                        item.getUnitPrice()
                ))
                .toList();

        BigDecimal subtotal = items.stream()
                .map(CartItemResponse::getTotalPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(
                cart.getId(),
                cart.getUserId(),
                cart.getStoreId(),
                items,
                subtotal
        );
    }


    // 4. Update product quantity
    @PutMapping("/items/{productId}")
    public CartItemResponse updateQuantity(
            @RequestHeader("X-USER-ID") UUID userId,
            @PathVariable UUID productId,
            @RequestParam Integer quantity
    ) {
        CartItem item = cartService.updateProductQuantity(
                userId, productId, quantity
        );

        return new CartItemResponse(
                item.getProductId(),
                item.getProductName(),
                item.getQuantity(),
                item.getUnitPrice()
        );
    }

    // 5. Remove product from cart
    @DeleteMapping("/items/{productId}")
    public String removeProduct(
            @RequestHeader("X-USER-ID") UUID userId,
            @PathVariable UUID productId
    ) {
        cartService.removeProduct(userId, productId);

        return "Product removed from cart successfully";
    }

}
