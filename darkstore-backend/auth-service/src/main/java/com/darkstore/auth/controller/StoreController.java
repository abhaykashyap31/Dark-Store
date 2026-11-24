package com.darkstore.auth.controller;

import com.darkstore.auth.dto.Dtos.StoreRequest;
import com.darkstore.auth.dto.Dtos.StoreResponse;
import com.darkstore.auth.service.StoreService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/stores")
public class StoreController {

    private final StoreService stores;

    public StoreController(StoreService stores) {
        this.stores = stores;
    }

    @GetMapping
    public List<StoreResponse> list() {
        return stores.list();
    }

    @GetMapping("/{id}")
    public StoreResponse get(@PathVariable UUID id) {
        return stores.get(id);
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StoreResponse create(@Valid @RequestBody StoreRequest r) {
        return stores.create(r);
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{id}")
    public StoreResponse update(@PathVariable UUID id, @Valid @RequestBody StoreRequest r) {
        return stores.update(id, r);
    }
}
