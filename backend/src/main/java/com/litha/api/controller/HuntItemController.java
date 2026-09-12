package com.litha.api.controller;
import com.litha.api.model.HuntItem; import com.litha.api.repository.HuntItemRepository; import org.springframework.data.jpa.repository.JpaRepository; import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/hunt-items") public class HuntItemController extends CrudController<HuntItem> { private final HuntItemRepository repo; public HuntItemController(HuntItemRepository repo) { this.repo = repo; } protected JpaRepository<HuntItem,Long> repository() { return repo; } }
