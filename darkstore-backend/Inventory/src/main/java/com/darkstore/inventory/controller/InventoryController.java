package com.darkstore.inventory.controller;

import com.darkstore.inventory.domain.StockMovement;
import com.darkstore.inventory.domain.StoreInventory;
import com.darkstore.inventory.dto.Dtos.*;
import com.darkstore.inventory.service.InventoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/inventory")
public class InventoryController {
    private final InventoryService inventory;

    public InventoryController(InventoryService inventory) {
        this.inventory = inventory;
    }

    @GetMapping
    public List<StoreInventory> stock(@RequestParam(required = false) UUID storeId) {
        return inventory.listStock(storeId);
    }

    @PutMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public StoreInventory upsertStock(@Valid @RequestBody StockRequest request) {
        return inventory.upsertStock(request);
    }

    @GetMapping("/{storeId}/{productId}")
    public StoreInventory stock(@PathVariable UUID storeId, @PathVariable UUID productId) {
        return inventory.getStock(storeId, productId);
    }

    @PostMapping("/adjust")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public StoreInventory adjust(@Valid @RequestBody StockAdjustment request) {
        return inventory.adjustStock(request);
    }

    @GetMapping("/low-stock")
    public List<StoreInventory> lowStock(@RequestParam(required = false) UUID storeId) {
        return inventory.lowStock(storeId);
    }

    @GetMapping("/movements")
    public List<StockMovement> movements(@RequestParam UUID storeId, @RequestParam UUID productId) {
        return inventory.movements(storeId, productId);
    }

    @PostMapping("/reserve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public ReserveResponse reserve(@Valid @RequestBody ReserveRequest request) {
        return inventory.reserve(request);
    }

    @PostMapping("/release")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ReserveResponse release(@Valid @RequestBody OrderRequest request) {
        return inventory.release(request.orderId());
    }

    @PostMapping("/confirm")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ReserveResponse confirm(@Valid @RequestBody OrderRequest request) {
        return inventory.confirm(request.orderId());
    }
}
