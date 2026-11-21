package com.darkstore.inventory.controller;

import com.darkstore.inventory.dto.Dtos.*;
import com.darkstore.inventory.service.InventoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/internal")
public class InternalInventoryController {
    private final InventoryService inventory;

    public InternalInventoryController(InventoryService inventory) {
        this.inventory = inventory;
    }

    @PostMapping("/products/validate")
    public ValidateResponse validate(@Valid @RequestBody ValidateRequest request) {
        return inventory.validate(request.storeId(), request.productIds());
    }

    @PostMapping("/inventory/reserve")
    @ResponseStatus(HttpStatus.CREATED)
    public ReserveResponse reserve(@Valid @RequestBody ReserveRequest request) {
        return inventory.reserve(request);
    }

    @PostMapping("/inventory/release")
    public ReserveResponse release(@Valid @RequestBody OrderRequest request) {
        return inventory.release(request.orderId());
    }

    @PostMapping("/inventory/confirm")
    public ReserveResponse confirm(@Valid @RequestBody OrderRequest request) {
        return inventory.confirm(request.orderId());
    }
}
