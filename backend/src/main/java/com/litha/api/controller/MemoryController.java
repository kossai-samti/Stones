package com.litha.api.controller;

import com.litha.api.model.Memory;
import com.litha.api.repository.MemoryRepository;
import com.litha.api.repository.StoneRepository;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/memories")
public class MemoryController extends CrudController<Memory> {
    private final MemoryRepository repo;
    private final StoneRepository stones;

    public MemoryController(MemoryRepository repo, StoneRepository stones) {
        this.repo = repo;
        this.stones = stones;
    }

    @Override
    protected JpaRepository<Memory, Long> repository() {
        return repo;
    }

    @Override
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Memory create(@RequestBody Memory memory) {
        if (memory.stone == null || memory.stone.id == null) {
            throw new IllegalArgumentException("A stone is required for a memory");
        }
        memory.stone = stones.findById(memory.stone.id)
                .orElseThrow(() -> new ResourceNotFoundException(memory.stone.id));
        return repo.save(memory);
    }

    @GetMapping(params = "stoneId")
    public List<Memory> byStone(@RequestParam Long stoneId) {
        return repo.findByStoneId(stoneId);
    }
}
