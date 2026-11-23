
package com.darkstore.cart_order_service.controller;

import com.darkstore.cart_order_service.dto.CheckoutResponse;
import com.darkstore.cart_order_service.entity.Order;
import com.darkstore.cart_order_service.service.CheckoutService;

import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/checkout")
public class CheckoutController {

    private final CheckoutService checkoutService;

    public CheckoutController(CheckoutService checkoutService) {
        this.checkoutService = checkoutService;
    }

    @PostMapping
    public CheckoutResponse checkout(
            @RequestHeader("X-USER-ID") UUID userId
    ) {
        Order order = checkoutService.checkout(userId);

        return new CheckoutResponse(
                order.getId(),
                order.getStatus(),
                order.getSubtotal(),
                order.getDeliveryFee(),
                order.getTotalAmount()
        );
    }
}
