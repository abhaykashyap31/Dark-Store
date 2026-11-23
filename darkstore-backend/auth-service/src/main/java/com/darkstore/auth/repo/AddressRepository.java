package com.darkstore.auth.repo;

import com.darkstore.auth.domain.Address;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AddressRepository extends JpaRepository<Address, UUID> {
    List<Address> findByUser_IdOrderByIdAsc(UUID userId);
    Optional<Address> findByIdAndUser_Id(UUID id, UUID userId);
}
