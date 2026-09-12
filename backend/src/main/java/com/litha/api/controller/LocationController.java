package com.litha.api.controller;
import com.litha.api.model.Location; import com.litha.api.repository.LocationRepository; import org.springframework.data.jpa.repository.JpaRepository; import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/locations") public class LocationController extends CrudController<Location> { private final LocationRepository repo; public LocationController(LocationRepository repo) { this.repo = repo; } protected JpaRepository<Location,Long> repository() { return repo; } }
