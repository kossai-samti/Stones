package com.litha.api.repository;
import com.litha.api.model.Location; import org.springframework.data.jpa.repository.JpaRepository;
public interface LocationRepository extends JpaRepository<Location, Long> { }
