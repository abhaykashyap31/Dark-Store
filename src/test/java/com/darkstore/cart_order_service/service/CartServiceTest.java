package com.darkstore.cart_order_service.service;

import com.darkstore.cart_order_service.entity.Cart;
import com.darkstore.cart_order_service.entity.CartItem;
import com.darkstore.cart_order_service.enums.CartStatus;
import com.darkstore.cart_order_service.integration.InventoryClient;
import com.darkstore.cart_order_service.repository.CartItemRepository;
import com.darkstore.cart_order_service.repository.CartRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CartServiceTest {

    @Mock
    private CartRepository cartRepository;
    @Mock
    private CartItemRepository cartItemRepository;
    @Mock
    private InventoryClient inventoryClient;

    @Test
    void cartItemsUseInventoryPriceAndRejectUnavailableQuantities() {
        UUID userId = UUID.randomUUID();
        UUID storeId = UUID.randomUUID();
        UUID cartId = UUID.randomUUID();
        UUID productId = UUID.randomUUID();
        Cart cart = new Cart();
        ReflectionTestUtils.setField(cart, "id", cartId);
        cart.setUserId(userId);
        cart.setStoreId(storeId);
        cart.setStatus(CartStatus.ACTIVE);

        when(cartRepository.findByUserIdAndStatus(userId, CartStatus.ACTIVE))
                .thenReturn(Optional.of(cart));
        when(inventoryClient.validateProducts(storeId, List.of(productId)))
                .thenReturn(List.of(new InventoryClient.AvailableProduct(
                        productId, "Inventory name", 3, new BigDecimal("4.25"))));
        when(cartItemRepository.findByCartIdAndProductId(cartId, productId))
                .thenReturn(Optional.empty());
        when(cartItemRepository.save(any(CartItem.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        CartService service = new CartService(cartRepository, cartItemRepository, inventoryClient);
        CartItem added = service.addProductToCart(userId, productId, 2);

        assertEquals("Inventory name", added.getProductName());
        assertEquals(new BigDecimal("4.25"), added.getUnitPrice());
        assertEquals(2, added.getQuantity());

        assertThrows(IllegalStateException.class,
                () -> service.addProductToCart(userId, productId, 4));
        verify(cartItemRepository, times(1)).save(any(CartItem.class));
    }
}
