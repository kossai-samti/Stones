package com.litha.api.controller;

import com.litha.api.model.AuditedEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

public abstract class CrudController<T extends AuditedEntity> {
    protected abstract JpaRepository<T, Long> repository();
    @GetMapping public List<T> all() { return repository().findAll(); }
    @GetMapping("/{id}") public T one(@PathVariable Long id) { return repository().findById(id).orElseThrow(() -> new ResourceNotFoundException(id)); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED) public T create(@RequestBody T value) { return repository().save(value); }
    @PutMapping("/{id}") public T replace(@PathVariable Long id, @RequestBody T value) { if (!repository().existsById(id)) throw new ResourceNotFoundException(id); value.id = id; return repository().save(value); }
    @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) public void delete(@PathVariable Long id) { if (!repository().existsById(id)) throw new ResourceNotFoundException(id); repository().deleteById(id); }
}
